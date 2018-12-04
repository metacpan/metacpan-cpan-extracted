package Protocol::DBus::Authn;

use strict;
use warnings;

use Module::Load ();

use IO::Framed ();

use Protocol::DBus::Authn::IO ();

use constant _CRLF => "\x0d\x0a";

sub new {
    my ($class, %opts) = @_;

    my @missing = grep { !$opts{$_} } qw( socket  mechanism );
    die "Need: @missing" if @missing;

    if (!ref $opts{'mechanism'}) {
        my $module = __PACKAGE__ . "::Mechanism::$opts{'mechanism'}";
        Module::Load::load($module);

        $opts{'mechanism'} = $module->new();
    }

    $opts{"_$_"} = delete $opts{$_} for keys %opts;

    $opts{'_io'} = IO::Framed->new( $opts{'_socket'} )->enable_write_queue();

    my $self = bless \%opts, $class;

    $self->{'_xaction'} = $self->_create_xaction();

    return $self;
}

sub negotiated_unix_fd {
    return $_[0]->{'_negotiated_unix_fd'} ? 1 : 0;
}

sub _create_xaction {
    my ($self) = @_;

    my $auth_label = 'AUTH';

    # Unless the mechanism sends its own initial NUL, might as well use the
    # same system call to send the initial NUL as we use to send the AUTH.
    if (!$self->{'_mechanism'}->must_send_initial()) {
        substr( $auth_label, 0, 0 ) = "\0";
    }

    # 0 = send; 1 = receive
    my @xaction = (
        [ 0 => $auth_label, $self->{'_mechanism'}->label(), $self->{'_mechanism'}->INITIAL_RESPONSE() ],
        $self->{'_mechanism'}->AFTER_AUTH(),

        [ 1 => \&_consume_ok ],

        $self->{'_mechanism'}->AFTER_OK(),

        [ 0 => 'BEGIN' ],
    );

    return \@xaction;
}

sub _consume_ok {
    my ($self, $line) = @_;

    if (index($line, 'OK ') == 0) {
        $self->{'_server_guid'} = substr($line, 3);
    }
    else {
        die "Unrecognized response: $line";
    }

    return;
}

sub pending_send {
    my ($self) = @_;

    my $next_is_receive = $self->{'_xaction'}[0];
    $next_is_receive &&= $next_is_receive->[0];

    if (!defined $next_is_receive) {
        die "Authn transaction is done!";
    }

    return !$next_is_receive;
}

sub go {
    my ($self) = @_;

    my $s = $self->{'_socket'};

    # Don’t send_initial() if !must_send_initial().
    $self->{'_sent_initial'} ||= !$self->{'_mechanism'}->must_send_initial() || $self->{'_mechanism'}->send_initial($s);

    if ($self->{'_sent_initial'}) {
      LINES:
        {
            if ( $self->{'_io'}->get_write_queue_count() ) {
                $self->{'_io'}->flush_write_queue() or last LINES;
            }

            while ( my $cur = $self->{'_xaction'}[0] ) {
                if ($cur->[0]) {
                    my $line = $self->_read_line() or last LINES;
                    $cur->[1]->($self, $line);
                }
                else {
                    $self->_send_line(join(' ', @{$cur}[ 1 .. $#$cur ])) or last LINES;
                }

                shift @{ $self->{'_xaction'} };
            }

            return 1;
        }
    }

    return undef;
}

sub cancel {
    my ($self) = @_;

    die 'unimplemented';
}

sub _send_line {
    my ($self) = @_;

    my $ok = $self->{'_io'}->write( $_[1] . _CRLF() );
    return $self->_flush_write_queue();
}

sub _flush_write_queue {
    my ($self) = @_;

    local $SIG{'PIPE'} = 'IGNORE';

    return $self->{'_io'}->flush_write_queue();
}

sub _read_line {
    my $line;

    if ($line = $_[0]->{'_io'}->read_until("\x0d\x0a")) {
        chop $line;
        chop $line;
    }

    return $line;
}

1;
