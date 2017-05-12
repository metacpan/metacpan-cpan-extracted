package Net::SSH::Any::Backend::Net_SSH2::DPipe;

use strict;
use warnings;

require Net::SSH::Any::DPipe;
our @ISA = qw(Net::SSH::Any::DPipe);

sub _make {
    my $class = shift;
    my $handle = Symbol::gensym();
    tie *$handle, join('::', $class, 'Tie'), @_;
    bless $handle, $class;
    $handle;
}

sub DESTROY {}

sub AUTOLOAD {
    our $AUTOLOAD;
    my ($name) = $AUTOLOAD =~ /([^:]*)$/;
    my $sub = sub { tied(*{shift()})->$name(@_) };
    no strict 'refs';
    *{$AUTOLOAD} = $sub;
    goto &$sub;
}

package Net::SSH::Any::Backend::Net_SSH2::DPipe::Tie;

use strict;
use warnings;

use Carp;
our @CARP_NOT = qw(Net::SSH::Any::Backend::Net_SSH2);

use Net::SSH::Any::Util qw($debug _debug);
use Net::SSH::Any::Constants qw(SSHA_EAGAIN);
use Symbol ();

require Tie::Handle;
our @ISA = qw(Tie::Handle);

sub TIEHANDLE {
    my ($class, $any, $channel) = @_;
    my $dpipe = { any => $any,
                 channel => $channel,
                 blocking => 1,
                 error => 0 };
    bless $dpipe, $class;
}

sub EOF {
    my $dpipe = shift;
    my $any = $dpipe->{any};
    my $channel = $dpipe->{channel};
    $channel->eof or ($dpipe->error and $dpipe->error != SSHA_EAGAIN);
}

sub READ {
    my ($dpipe, undef, $len, $off, $ext) = @_;
    my $any = $dpipe->{any};
    my $channel = $dpipe->{channel};
    my $blocking = $dpipe->{blocking};
    $any->_clear_error or return;

    if (defined $len) {
        return 0 if $len <= 0;
    }
    else {
        $len = 34000;
    }

    $ext //= 0;

    my $bytes;
    if ($off) {
        $_[1] = '' unless defined $_[1];
        if ($off < 0) {
            $off += length $_[1];
            croak "Offset outside string" if $off < 0;
        }
        elsif (my $after = length($_[1]) - $off) {
            if ($after > 0) {
                $_[1] .= ("\x00" x $after);
            }
            else { # $after < 0
                substr ($_[1], $off) = '';
            }
        }
        $bytes = $any->_channel_read($channel, $blocking, my ($buf), $len, $ext);
        $_[1] .= $buf if $bytes;
    }
    else {
        $bytes = $any->_channel_read($channel, $blocking, $_[1], $len, $ext);
        $_[1] //= '';
    }
    $bytes || $dpipe->_check_error($bytes);
}

sub WRITE {
    my ($dpipe, undef, $len, $off) = @_;
    my $any = $dpipe->{any};
    my $channel = $dpipe->{channel};
    my $blocking = $dpipe->{blocking};
    $any->_clear_error or return;
    my $bytes;
    if ($off or defined $len) {
        if (defined $off) {
            if ($off < 0) {
                $off += length $_[1];
                croak "Offset outside string" if $off < 0;
            }
            elsif ($off >= length $_[1]) {
                return 0;
            }
        }
        else {
            $off = 0;
        }

        $len = length $_[1] - $off unless defined $len;
        return $dpipe->_check_error unless $len > 0;
        $bytes = $any->_channel_do($channel, $blocking, 'write', substr($_[1], $off, $len));
    }
    else {
        $bytes = $any->_channel_do($channel, $blocking, 'write', $_[1]);
    }
    $bytes || $dpipe->_check_error($bytes);
}

sub PRINT {
    my $dpipe = shift;
    my $any = $dpipe->{any};
    my $channel = $dpipe->{channel};
    my $buf = '';
    my $total = 0;
    $debug and $debug & 8192 and _debug ("$dpipe->PRINT(...)");

    while (1) {
        while (length $buf < 34000 and @_) {
            $buf .= $, if defined $,;
            $buf .= shift;
            $buf .= $\ if defined $\ and not @_;
        }

        return $total unless length $buf;

        my $bytes = $any->_channel_do($channel, 1, 'write', $buf)
            or return $dpipe->_check_error;
        $total += $bytes;
        substr($buf, 0, $bytes, '');
    }
}

sub PRINTF {
    my $dpipe = shift;
    my $str = sprintf(@_);
    local $\;
    $dpipe->PRINT($str);
}

sub GETC {
    my $dpipe = shift;
    $dpipe->READ(my ($buf), 1);
    return $buf;
}

sub READLINE {
    my $dpipe = shift;
    my $any = $dpipe->{any};
    my $channel = $dpipe->{channel};
    $any->_clear_error or return;
    my $line = '';
    # TODO: optimize the case where $/ is undef reading in chunks
    my $off = (defined $/ ? -length $/ : undef);
    while (1) {
        unless ($any->_channel_read($channel, 1, my ($char), 1)) {
            $dpipe->_check_error;
            return (length($line) ? $line : undef);
        }
        if ( defined $off) {
            ++$off >= 0 and substr($line, $off) eq $/ and return $line;
        }
    }
}

sub CLOSE {
    my $dpipe = shift;
    my $any = $dpipe->{any};
    my $channel = $dpipe->{channel};
    $any->_channel_close($dpipe->{channel});
    $any->_check_child_error or $dpipe->_check_error;
}

sub FILENO { shift->{any}{be_fileno} }

sub blocking {
    my $dpipe = shift;
    $dpipe->{blocking} = !!shift if @_;
    $dpipe->{blocking};
}

# Net_SSH2 backend uses 0 to indicate that everything went well but
# that nothing was actually done. Perl uses 0 to indicate EOF. The
# following subroutine converts between both.
sub _check_error {
    my ($dpipe, $bytes) = @_;
    if (defined $bytes) {
        return $bytes if $bytes;
        $! = Errno::EAGAIN();
    }
    else {
        $dpipe->{error} = $dpipe->{any}->error or return 0; # EOF!
        $! = Errno::EIO();
    }
    return
}

*sysread = \&READ;
*syswrite = \&WRITE;
*getc = \&GETC;
*close = \&CLOSE;
*print = \&PRINT;
*printf = \&PRINTF;

sub error { shift->{error} }

1;
