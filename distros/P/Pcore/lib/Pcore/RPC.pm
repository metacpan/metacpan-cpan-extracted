package Pcore::RPC;

use Pcore -class;
use Pcore::Util::Scalar qw[is_blessed_ref is_plain_arrayref is_plain_hashref weaken];
use Pcore::RPC::Proc;
use Pcore::WebSocket;

has token => ( is => 'ro', isa => Maybe [Str], init_arg => undef );
has workers     => ( is => 'ro', isa => ArrayRef, default => sub { [] }, init_arg => undef );
has connections => ( is => 'ro', isa => ArrayRef, default => sub { [] }, init_arg => undef );

sub TO_DATA ( $self, ) {
    return {
        connect => $self->get_connect,
        token   => $self->{token},
    };
}

sub run_rpc ( $self, $class, @ ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    my %args = (
        workers   => undef,    # FALSE - max. CPUs, -n - CPUs - n || 1
        listen    => undef,
        token     => undef,
        buildargs => undef,    # Maybe[HashRef], RPC object constructor arguments
        on_ready  => undef,    # Maybe[CodeRef]
        @_[ 2 .. $#_ ],
    );

    # define number of the workers
    if ( !$args{workers} ) {
        $args{workers} = P->sys->cpus_num;
    }
    elsif ( $args{workers} < 0 ) {
        $args{workers} = P->sys->cpus_num - $args{workers};

        $args{workers} = 1 if $args{workers} <= 0;
    }

    my $rpc = bless { token => $args{token} }, $self;

    my $cv = AE::cv sub {
        $args{on_ready}->($rpc) if $args{on_ready};

        $blocking_cv->($rpc) if $blocking_cv;

        return;
    };

    $cv->begin;

    my $weaken_rpc = $rpc;

    weaken $weaken_rpc;

    # create workers
    for ( 1 .. $args{workers} ) {
        $cv->begin;

        Pcore::RPC::Proc->new(
            listen    => $args{listen},
            token     => $args{token},
            class     => $class,
            buildargs => $args{buildargs},
            on_ready  => sub ($proc) {
                push $rpc->{workers}->@*, $proc;

                $cv->end;

                return;
            },
            on_finish => sub ($proc) {
                if ($weaken_rpc) {
                    for ( my $i = 0; $i <= $weaken_rpc->{workers}->$#*; $i++ ) {
                        if ( $weaken_rpc->{workers}->[$i] eq $proc ) {
                            splice $weaken_rpc->{workers}->@*, $i, 1, ();

                            last;
                        }
                    }
                }

                return;
            }
        );
    }

    $cv->end;

    return $blocking_cv ? $blocking_cv->recv : ();
}

sub connect_rpc ( $self, % ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    my %args = (
        connect        => undef,
        token          => undef,
        listen_events  => undef,
        forward_events => undef,
        on_connect     => undef,
        @_[ 1 .. $#_ ],
    );

    # parse connect
    if ( is_blessed_ref $self ) {
        $args{connect} = $self->get_connect;

        $args{token} = $self->token;
    }
    else {
        $self = bless {}, $self;

        if ( is_plain_hashref $args{connect} ) {
            $args{token} = $args{connect}->{token} if exists $args{connect}->{token};

            $args{connect} = $args{connect}->{connect};
        }

        $args{connect} = [ $args{connect} ] if !is_plain_arrayref $args{connect};
    }

    die q[No addresses specified] if !$args{connect}->@*;

    my $cv = AE::cv sub {
        $args{on_connect}->($self) if $args{on_connect};

        $blocking_cv->($self) if $blocking_cv;

        return;
    };

    $cv->begin;

    my $self_weak = $self;

    weaken $self_weak;

    for my $addr ( $args{connect}->@* ) {
        $cv->begin;

        Pcore::WebSocket->connect_ws(
            "ws://$addr/",
            protocol       => 'pcore',
            before_connect => {
                token          => $args{token},
                listen_events  => $args{listen_events},
                forward_events => $args{forward_events},
            },
            on_listen_event => sub ( $ws, $mask ) {    # RPC server can listen client event
                return 1;
            },
            on_fire_event => sub ( $ws, $key ) {       # RPC server can fire client event
                return 1;
            },
            on_connect_error => sub ($status) {
                die "$status";
            },
            on_connect => sub ( $ws, $headers ) {
                push $self->{connections}->@*, $ws;

                $cv->end;

                return;
            },
            on_disconnect => sub ( $ws, $status ) {
                if ($self_weak) {

                    # remove destroyed connection from cache
                    for ( my $i = 0; $i <= $self_weak->{connections}->$#*; $i++ ) {
                        if ( $self_weak->{connections}->[$i] eq $ws ) {
                            splice $self_weak->{connections}->@*, $i, 1, ();

                            last;
                        }
                    }
                }

                return;
            }
        );
    }

    $cv->end;

    return $blocking_cv ? $blocking_cv->recv : ();
}

sub get_connect ($self) {
    return [ map { $_->{listen} } $self->{workers}->@* ];
}

sub rpc_call ( $self, $method, @ ) {
    my $ws = shift $self->{connections}->@*;

    push $self->{connections}->@*, $ws;

    $ws->rpc_call( @_[ 1 .. $#_ ] );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 75, 171              | ControlStructures::ProhibitCStyleForLoops - C-style "for" loop used                                            |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::RPC

=head1 SYNOPSIS

    # client
    my $RPC;

    P->pm->run_rpc(
        'RPC',
        workers   => 1,
        token     => undef,
        buildargs => {},
        on_ready  => sub ($rpc) {
            $RPC = $rpc;

            $RPC->connect_rpc(
                token          => undef,
                listen_events  => ['APP.EV1'],
                forward_events => ['APP.EV2'],
                on_connect     => sub ($rpc) {
                    $rpc->rpc_call(
                        'test', 123,
                        sub {
                            say dump \@_;

                            # terminate RPC
                            P->fire_event('RPC.TERM');

                            return;
                        }
                    );

                    return;
                }
            );

            return;
        },
    );

    # server
    package RPC;

    use Pcore -rpc, -const, -class;

    const our $RPC_LISTEN_EVENTS  => ['APP.EV2'];
    const our $RPC_FORWARD_EVENTS => ['APP.EV1'];

    sub BUILD ( $self, $args ) {
        return;
    }

    sub RPC_ON_CONNECT ( $self, $ws ) {
        return;
    }

    sub RPC_ON_DISCONNECT ( $self, $ws, $status ) {
        return;
    }

    sub RPC_ON_TERM ($self) {
        return;
    }

    sub API_test ( $self, $req, $args ) {
        $req->( 200, time );

        return;
    }

    1;

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
