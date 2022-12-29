package Net::mbedTLS::Connection::Tied;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::mbedTLS::Connection::Tied

=head1 SYNOPSIS

    my $fh = IO::Socket::INET->new('perl.org:443');

    my $tls_fh = Net::mbedTLS->new()->create_client($fh)->tied_fh();

… and C<$tls_fh> works like an ordinary Perl filehandle.

=head1 DESCRIPTION

This module is a bit like L<IO::Socket::SSL>: it lets you
use Perl’s I/O builtins (e.g., C<print>) to speak TLS.

Notable differences from IO::Socket::SSL include:

=over

=item * You don’t instantiate this class directly; instead,
create a L<Net::mbedTLS::Connection>, and have I<that> object
create an instance of this class.

=item * mbedTLS does its own hostname verification, which obviates
much of IO::Socket::SSL’s implementation logic.

=back

=cut

#----------------------------------------------------------------------

use Errno ();
use Symbol ();

our $TLS_ERROR;

use constant _DEBUG => 0;

#----------------------------------------------------------------------

sub new {
    my ($class, $tls) = @_;

    my $sym = Symbol::gensym();

    return tie *$sym, $class, $sym, $tls;
}

sub TIEHANDLE {
    my ($class, $symref, $tls) = @_;

    _DEBUG && _debug();

    ${*$symref}{'tls'} = $tls;

    return bless $symref, $class;
}

sub FILENO {
    my ($self) = @_;

    _DEBUG && _debug();

    return fileno( ${*$self}{'tls'}->fh() );
}

sub READ {
    my ($self, undef, $length, $offset) = @_;

    _DEBUG && _debug();

    my $tls = ${*$self}{'tls'};

    my $buf_sr = \$_[1];
    if (!defined $$buf_sr) {
        $$buf_sr = q<>;
    }

    $offset ||= 0;

    if ($offset < 0) {
        $offset = length($$buf_sr) + $offset;
    }

    my $buf = "\0" x ($length - $offset);

    my $got = $tls->read($buf);

    if ($got) {
        substr $$buf_sr, 0, length $buf, $buf;
        return $got;
    }

    return 0 if $tls->closed();

    $! = Errno::EAGAIN();

    $TLS_ERROR = $tls->error();

    return undef;
}

sub WRITE {
    my ($self, $src, $length, $offset) = @_;

    _DEBUG && _debug();

    my $tls = ${*$self}{'tls'};

    my $sent;

    if (defined $length) {
        $offset ||= 0;

        $sent = $tls->write( substr($src, $offset, $length) );
    }
    else {
        $sent = $tls->write($src);
    }

    return $sent if $sent;

    return 0 if $tls->closed();

    $! = Errno::EAGAIN();

    $TLS_ERROR = $tls->error();

    return undef;
}

sub GETC {
    my ($self) = @_;

    $! = undef;

    my $got = $self->READ(my $buf, 1);

    return $got ? $buf : undef;
}

sub PRINT {
    my ($self, @pieces) = @_;

    local $, = q<> if !defined $,;
    local $\ = q<> if !defined $\;

    return $self->WRITE( join($,, @pieces) . $\ );
}

sub PRINTF {
    my ($self, $fmt, @vars) = @_;

    return $self->PRINT( sprintf($fmt, @vars) );
}

sub CLOSE {
    my ($self) = @_;

    _DEBUG && _debug();

    my $tls = ${*$self}{'tls'};

    my $fh = $tls->fh();

    $fh->blocking(0);

    # Let’s try to be nice and shut down the TLS layer before we kill
    # the underlying TCP connection.
    #
    $tls->close_notify();

    # This “graceful” TCP close prevents our kernel from sending
    # TCP RST to the peer. (We don’t really care about whatever may
    # fail here.)
    #
    shutdown $fh, 0;
    1 while sysread $fh, my $buf, 512;

    # … and now, finally, close the TCP socket:
    #
    return close $fh;
}

sub _debug {
    my ($msg) = @_;

    my $fn = (caller 1)[3];

    print STDERR $fn;
    print STDERR ": $msg" if length $msg;
    print STDERR "\n";
}

1;
