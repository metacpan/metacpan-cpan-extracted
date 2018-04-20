package Pcore::RPC::Hub;

use Pcore -class, -res;
use Pcore::Util::Scalar qw[refaddr weaken is_plain_coderef is_blessed_ref];
use Pcore::RPC::Proc;
use Pcore::WebSocket;

has id        => ( is => 'ro', isa => Maybe [Str] );
has type      => ( is => 'ro', isa => Maybe [Str] );
has parent_id => ( is => 'ro', isa => Maybe [Str] );

has proc      => ( is => 'ro', isa => HashRef,  init_arg => undef );    # child RPC processes
has conn      => ( is => 'ro', isa => HashRef,  init_arg => undef );
has conn_type => ( is => 'ro', isa => ArrayRef, init_arg => undef );

has _on_rpc_started => ( is => 'ro', init_arg => undef );               # event listener

sub BUILD ( $self, $args ) {
    if ( defined $self->{id} ) {
        weaken $self;

        $self->{_on_rpc_started} = P->listen_events(
            'RPC.HUB.UPDATED.' . $self->{parent_id},
            sub ($ev) {
                for my $conn ( $ev->{data}->@* ) {

                    # do not connect to the already connected servers
                    next if exists $self->{conn}->{ $conn->{id} };

                    # do not connect to the RPC servers with the same type
                    next if defined $self->{type} && $self->{type} eq $conn->{type};

                    # do not connect to myself
                    next if defined $self->{id} && $self->{id} eq $conn->{id};

                    $self->_connect_rpc($conn);
                }

                return;
            }
        );
    }

    return;
}

sub run_rpc ( $self, @args ) {
    my $cb = Coro::rouse_cb;

    my $cv = AE::cv sub { $cb->() };

    $cv->begin;

    weaken $self;

    for my $rpc (@args) {

        # resolve number of the workers
        if ( !$rpc->{workers} ) {
            $rpc->{workers} = P->sys->cpus_num;
        }
        elsif ( $rpc->{workers} < 0 ) {
            $rpc->{workers} = P->sys->cpus_num - $rpc->{workers};

            $rpc->{workers} = 1 if $rpc->{workers} <= 0;
        }

        # run workers
        for ( 1 .. $rpc->{workers} ) {
            $cv->begin;

            Pcore::RPC::Proc->new(
                $rpc->{type},
                parent_id => refaddr $self,
                listen    => $rpc->{listen},
                token     => $rpc->{token},
                buildargs => $rpc->{buildargs},
                on_ready  => sub ($proc) {
                    $self->{proc}->{ $proc->{conn}->{id} } = $proc;

                    $self->_connect_rpc(
                        $proc->{conn},
                        $rpc->{listen_events},
                        $rpc->{forward_events},
                        sub {

                            # send updated routes to all connected RPC servers
                            P->fire_event( 'RPC.HUB.UPDATED.' . refaddr $self, [ values $self->{conn}->%* ] );

                            $cv->end;

                            return;
                        }
                    );

                    return;
                },
                on_finish => sub ($proc) {
                    $self->_on_proc_finish($proc) if defined $self;

                    return;
                }
            );
        }
    }

    $cv->end;

    Coro::rouse_wait $cb;

    return res 200;
}

sub _connect_rpc ( $self, $conn, $listen_events = undef, $forward_events = undef, $cb = undef ) {
    weaken $self;

    $self->{conn}->{ $conn->{id} } = $conn;

    Pcore::WebSocket->connect_ws(
        "ws://$conn->{listen}/",
        protocol       => 'pcore',
        before_connect => {
            token          => $conn->{token},
            listen_events  => $listen_events,
            forward_events => defined $self->{id} ? $forward_events : [ 'RPC.HUB.UPDATED.' . refaddr $self, defined $forward_events ? $forward_events->@* : () ],
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

            # store established connection
            push $self->{conn_type}->{ $conn->{type} }->@*, $ws;

            $cb->() if defined $cb;

            return;
        },
        on_disconnect => sub ( $ws, $status ) {
            $self->_on_rpc_disconnect( $conn, $ws, $status ) if defined $self;

            return;
        }
    );

    return;
}

sub _on_proc_finish ( $self, $proc ) {
    delete $self->{proc}->{ $proc->{conn}->{id} };

    return;
}

sub _on_rpc_disconnect ( $self, $conn, $ws, $status ) {
    delete $self->{conn}->{ $conn->{id} };

    # remove destroyed connection from cache
    my $conn_type = $self->{conn_type}->{ $conn->{type} };

    for ( my $i = 0; $i <= $conn_type->$#*; $i++ ) {
        if ( $conn_type->[$i] eq $ws ) {
            splice $conn_type->@*, $i, 1, ();

            last;
        }
    }

    return;
}

sub rpc_call ( $self, $type, $method, @args ) {
    my $cb = is_plain_coderef $args[-1] || ( is_blessed_ref $args[-1] && $args[-1]->can('IS_CALLBACK') ) ? pop @args : undef;

    my $ws = shift $self->{conn_type}->{$type}->@*;

    if ( !defined $ws ) {
        my $res = res [ 404, qq[RPC type "$type" is not available] ];

        return $cb ? $cb->($res) : $res;
    }

    push $self->{conn_type}->{$type}->@*, $ws;

    if ( defined wantarray ) {
        $ws->rpc_call( $method, \@args, my $rouse_cb = Coro::rouse_cb );

        # block
        my $res = Coro::rouse_wait $rouse_cb;

        return $cb ? $cb->($res) : $res;
    }
    else {
        $ws->rpc_call( $method, \@args, $cb );

        return;
    }
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 114                  | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 167                  | ControlStructures::ProhibitCStyleForLoops - C-style "for" loop used                                            |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::RPC::Hub

=head1 SYNOPSIS

    # client
    my $hub = Pcore::RPC::Hub->new;

    $hub->run_rpc( {
        type           => 'RPC',
        workers        => 50,
        token          => undef,
        listen_events  => undef,
        forward_events => ['APP.SETTINGS_UPDATED'],
        buildargs      => {},
    } );

    $hub->rpc_call( 'RPC', 'test', @args, $cb );

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
