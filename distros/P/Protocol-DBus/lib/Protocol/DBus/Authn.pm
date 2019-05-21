package Protocol::DBus::Authn;

use strict;
use warnings;

use IO::Framed ();
use Module::Runtime ();
use Socket ();

use Protocol::DBus::X ();

use constant _CRLF => "\x0d\x0a";

use constant DEBUG => 0;

sub new {
    my ($class, %opts) = @_;

    my @missing = grep { !$opts{$_} } qw( socket  mechanism );
    die "Need: @missing" if @missing;

    $opts{"_$_"} = delete $opts{$_} for keys %opts;

    $opts{'_can_pass_unix_fd'} = Socket::MsgHdr->can('new');
    $opts{'_can_pass_unix_fd'} &&= Socket->can('SCM_RIGHTS');
    $opts{'_can_pass_unix_fd'} &&= _is_unix_socket($opts{'_socket'});

    $opts{'_io'} = IO::Framed->new( $opts{'_socket'} )->enable_write_queue();

    my $self = bless \%opts, $class;

    $self->_set_mechanism( $opts{'_mechanism'} ) or do {
        die "“$opts{'_mechanism'}” is not a valid authn mechanism.";
    };

    return $self;
}

sub _set_mechanism {
    my ($self, $mechanism) = @_;

    if (!ref $mechanism) {
        my $module = __PACKAGE__ . "::Mechanism::$mechanism";

        my $err = $@;
        if (!eval { Module::Runtime::require_module($module); 1 } ) {
            DEBUG && print STDERR "Failed to load $mechanism authn module: $@";
            return 0;
        }
        $@ = $err;

        $self->{'_mechanism'} = $module->new();
    }

    $self->{'_xaction'} = $self->_create_xaction();

    return 1;
}

sub negotiated_unix_fd {
    return $_[0]->{'_negotiated_unix_fd'} ? 1 : 0;
}

# Whether a send is pending (1) or a receive (0).
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
                $self->flush_write_queue() or last LINES;
            }

            my $dollar_at = $@;
            my $ok = eval {
                while ( my $cur = $self->{'_xaction'}[0] ) {
                    if ($cur->[0]) {
                        my $line = $self->_read_line() or last LINES;
                        $cur->[1]->($self, $line);
                    }
                    else {
                        my @line_parts;

                        if ('CODE' eq ref $cur->[1]) {
                            @line_parts = $cur->[1]->($self);
                        }
                        else {
                            @line_parts = @{$cur}[ 1 .. $#$cur ];
                        }

                        $self->_send_line("@line_parts") or last LINES;

                        push @{ $self->{'_tried_mechanism'} }, $self->{'_mechanism'}->label();
                    }

                    shift @{ $self->{'_xaction'} };
                }

                1;
            };

            if (!$ok) {
                my $err = $@;
                if (eval { $err->isa('Protocol::DBus::X::Rejected') }) {

                    $self->{'_mechanism'}->on_rejected();

                    my @to_try;

                    for my $mech ( @{ $err->get('mechanisms') } ) {
                        if (!grep { $_ eq $mech } @{ $self->{'_tried_mechanism'} }) {
                            push @to_try, $mech;
                        }
                    }

                    while (my $mech = shift @to_try) {
                        if ($self->_set_mechanism($mech)) {
                            redo LINES;
                        }
                    }

                    die "Exhausted all authentication mechanisms! (@{ $self->{'_tried_mechanism'} })";
                }
                else {
                    local $@ = $err;
                    die;
                }
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

sub _create_xaction {
    my ($self) = @_;

    my $auth_label = 'AUTH';

    # Unless the mechanism sends its own initial NUL, might as well use the
    # same system call to send the initial NUL as we use to send the AUTH.
    if (!$self->{'_sent_initial'} && !$self->{'_mechanism'}->must_send_initial()) {
        substr( $auth_label, 0, 0 ) = "\0";
    }

    # 0 = send; 1 = receive
    my @xaction = (
        [ 0 => $auth_label, $self->{'_mechanism'}->label(), $self->{'_mechanism'}->INITIAL_RESPONSE() ],

        # e.g., for exchange of DATA
        $self->{'_mechanism'}->AFTER_AUTH(),

        [ 1 => \&_consume_ok ],
    );

    if ($self->{'_can_pass_unix_fd'}) {
        push @xaction, (
            [ 0 => 'NEGOTIATE_UNIX_FD' ],
            [ 1 => \&_consume_agree_unix_fd ],
        );
    }

    push @xaction, [ 0 => 'BEGIN' ];

    return \@xaction;
}

sub _consume_agree_unix_fd {
    my ($self, $line) = @_;

    if ($line eq 'AGREE_UNIX_FD') {
        $self->{'_negotiated_unix_fd'} = 1;
    }
    elsif (index($line, 'ERROR ') == 0) {
        warn "Server rejected unix fd passing: " . substr($line, 6) . $/;
    }

    return;
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

sub _send_line {
    my ($self) = @_;

    DEBUG() && print STDERR "AUTHN SENDING: [$_[1]]$/";

    $self->{'_io'}->write( $_[1] . _CRLF() );

    return $self->_flush_write_queue();
}

sub _flush_write_queue {
    my ($self) = @_;

    local $SIG{'PIPE'} = 'IGNORE';

    return $self->{'_io'}->flush_write_queue();
}

sub _read_line {
    my $line;

    DEBUG() && print STDERR "AUTHN RECEIVING …$/";

    if ($line = $_[0]->{'_io'}->read_until("\x0d\x0a")) {
        substr( $line, -2 ) = q<>;

        DEBUG() && print STDERR "AUTHN RECEIVED: [$line]$/";

        if (0 == index( $line, 'REJECTED ')) {
            die Protocol::DBus::X->create(
                'Rejected',
                split( m< >, substr( $line, 9 ) ),
            );
        }
    }

    return $line;
}

sub _is_unix_socket {
    my ($sk) = @_;

    my $sname = getsockname($sk) or die "getsockname(): $!";

    return Socket::sockaddr_family($sname) == Socket::AF_UNIX();
}

1;
