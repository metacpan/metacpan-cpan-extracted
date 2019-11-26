package Pcore::Node;

use Pcore -class, -res, -const;
use Pcore::Util::Scalar qw[weaken refaddr is_ref is_blessed_hashref is_plain_hashref];
use Pcore::HTTP::Server;
use Pcore::Node::Server;
use Pcore::Node::Proc;
use Pcore::WebSocket::pcore;
use Pcore::Util::UUID qw[uuid_v4_str];

has type     => ( required => 1 );
has server   => ();                  # InstanceOf['Pcore::Node::Server'], $uri, HashRef, if not specified - local server will be created
has listen   => ();
has requires => ();                  # HashRef, required nodes types

has on_status => ();                 # CodeRef, ->($self, $new_status, $old_status)
has on_rpc    => ();                 # CodeRef, ->($self, $req, $tx)
has on_event  => ();                 # CodeRef, ->($self, $ev)

has reconnect_timeout   => 3;
has compression         => 0;         # use websocket compression
has pong_timeout        => 60 * 5;    # for websocket client
has wait_online_timeout => ();        # default wait_online timeout, false - wait forever

has id                => ( sub {uuid_v4_str}, init_arg => undef );    # my node id
has is_online         => ( init_arg                    => undef );    # node online status
has server_is_online  => ( init_arg                    => undef );    # node server status
has status            => ( init_arg                    => undef );    # node status
has _has_requires     => ( init_arg                    => undef );
has _server_is_remote => ( init_arg                    => undef );
has _remote_server_h  => ( init_arg                    => undef );    # remote node server connection handle
has _http_server      => ( init_arg                    => undef );    # InstanceOf['Pcore::HTTP::Server']
has _wait_online_cb   => ( init_arg                    => undef );    # HashRef, wait online callbacks, callback_id => sub
has _wait_node_cb     => ( init_arg                    => undef );    # HashRef, wait node callbacks by node type, callback_id => sub
has _node_proc        => ( init_arg                    => undef );    # HashRef, running nodes processes
has _on_rpc           => ( init_arg                    => undef );    # on_rpc callback wrapper
has _on_event         => ( init_arg                    => undef );    # on_event callback wrapper

# TODO
has _nodes       => ( init_arg => undef );                            # ArrayRef, nodes table
has _conn_nodes  => ( init_arg => undef );                            # HashRef, connecting nodes
has _all_conn    => ( init_arg => undef );                            # HashRef, connected nodes, hashed by id
has _ready_conn  => ( init_arg => undef );                            # HashRef, READY nodes connections by node type
has _online_conn => ( init_arg => undef );                            # HashRef, ONLINE nodes connections by node type

const our $NODE_STATUS_UNKNOWN    => 1;
const our $NODE_STATUS_OFFLINE    => 2;                               # blocked
const our $NODE_STATUS_CONNECTING => 3;                               # blocked, connecting to required nodes
const our $NODE_STATUS_CONNECTED  => 4;                               # blocked, connected to the all required nodes
const our $NODE_STATUS_READY      => 5;                               # blocked, all required nodes are in the CONNECTED state
const our $NODE_STATUS_ONLINE     => 6;                               # unblocked, all required nodes are in the READY or ONLINE state

const our $NODE_STATUS_REASON => {
    $NODE_STATUS_UNKNOWN    => 'unknown',
    $NODE_STATUS_OFFLINE    => 'offline',
    $NODE_STATUS_CONNECTING => 'connecting',
    $NODE_STATUS_CONNECTED  => 'connected',
    $NODE_STATUS_READY      => 'ready',
    $NODE_STATUS_ONLINE     => 'online',
};

sub BUILD ( $self, $args ) {
    $self->{_has_requires} = do {
        if ( !defined $self->{requires} ) {
            undef;
        }
        elsif ( !$self->{requires}->%* ) {
            undef;
        }
        elsif ( keys $self->{requires}->%* == 1 && exists $self->{requires}->{'*'} ) {
            undef;
        }
        else {
            1;
        }
    };

    # resolve listen
    $self->{listen} = P->uri( $self->{listen}, base => 'ws:', listen => 1 ) if !is_ref $self->{listen};

    # generate token
    $self->{listen}->set_username(uuid_v4_str) if !defined $self->{listen}->{username};

    # init node status
    $self->{status} = $self->{_has_requires} ? $NODE_STATUS_CONNECTING : $NODE_STATUS_ONLINE;
    $self->{is_online} = $self->{status} == $NODE_STATUS_ONLINE ? 1 : 0;

    $self->{on_status}->( $self, $self->{status}, $NODE_STATUS_UNKNOWN ) if defined $self->{on_status};

    $self->{_on_rpc}   = $self->_build__on_rpc;
    $self->{_on_event} = $self->_build__on_event;

    $self->_run_http_server;

    # remote server
    if ( defined $self->{server} && ( !is_ref $self->{server} || ( is_blessed_hashref $self->{server} && $self->{server}->isa('Pcore::Util::URI') ) ) ) {
        $self->{_server_is_remote} = 1;
        $self->{server_is_online}  = 0;

        # convert to uri object
        $self->{server} = P->uri( $self->{server}, base => 'ws:' ) if !is_ref $self->{server};

        $self->_connect_to_remote_server;
    }

    # local server
    else {
        $self->{_server_is_remote} = 0;
        $self->{server_is_online}  = 1;

        # create local server if not instance of Pcore::Node::Server
        if ( ref $self->{server} ne 'Pcore::Node::Server' ) {
            $self->{server} = Pcore::Node::Server->new( $self->{server} // () );
        }

        $self->{server}->register_node( $self, $self->{id}, $self->_get_node_register_data );
    }

    return;
}

sub _build__on_rpc ($self) {
    return if !defined $self->{on_rpc};

    weaken $self;

    return sub ( $h, $tx ) {
        if ( !defined $self ) {
            return [ 1013, 'Node Destroyed' ];
        }
        elsif ( $self->{status} < $NODE_STATUS_READY ) {
            return [ 1013, 'Node is Offline' ];
        }
        elsif ( defined $self->{listen}->{username} && !$h->{auth} ) {
            $h->disconnect;
        }
        else {
            return $self->{on_rpc}->( $self, $tx );
        }

        return;
    };
}

sub _build__on_event ($self) {
    return if !defined $self->{on_event};

    weaken $self;

    return sub ( $h, $ev ) {
        return if !defined $self;

        if ( $self->{status} >= $NODE_STATUS_READY ) {
            $self->{on_event}->( $self, $ev );
        }

        return;
    };
}

sub _get_node_register_data ($self) {
    return {
        id       => $self->{id},
        type     => $self->{type},
        listen   => $self->{listen},
        status   => $self->{status},
        requires => $self->{requires},
    };
}

sub _get_bindings ( $self, $node_type ) {
    return if !defined $self->{on_event};

    if ( defined( my $requires = $self->{requires} ) ) {
        return $requires->{$node_type} if exists $requires->{$node_type};

        return $requires->{'*'} if exists $requires->{'*'};
    }

    return;
}

# CONNECT TO SERVER
sub _connect_to_remote_server ($self) {
    state $RPC_METHOD = {
        _on_node_register => 1,
        _on_node_add      => 1,
        _on_node_update   => 1,
        _on_node_remove   => 1
    };

    weaken $self;

    Coro::async_pool {
        return if !defined $self;

        my $h = Pcore::WebSocket::pcore->connect(
            $self->{server},
            compression   => $self->{compression},
            pong_timeout  => $self->{pong_timeout},
            token         => [ $self->{server}->{username}, $self->{id}, $self->_get_node_register_data ],
            on_disconnect => sub ($h) {

                # node was destroyed
                return if !defined $self;

                undef $self->{_remote_server_h};
                $self->{server_is_online} = 0;

                # reconnect to server
                my $t;

                $t = AE::timer $self->{reconnect_timeout}, 0, sub {

                    # node was destroyed
                    return if !defined $self;

                    undef $t;

                    $self->_connect_to_remote_server;

                    return;
                };

                return;
            },
            on_rpc => sub ( $h, $tx ) {

                # node was destroyed
                return if !defined $self;

                if ( exists $RPC_METHOD->{ $tx->{method} } ) {
                    my $method = $tx->{method};

                    return $self->$method( $tx->{args}->@* );
                }

                return;
            },
        );

        # connected to the node server
        if ($h) {
            $self->{_remote_server_h} = $h;
            $self->{server_is_online} = 1;
        }

        return;
    };

    return;
}

# TODO on_bind
sub _run_http_server ($self) {
    weaken $self;

    $self->{_http_server} = Pcore::HTTP::Server->new(
        listen     => $self->{listen},
        on_request => sub ($req) {
            if ( $req->is_websocket_connect_request ) {
                return Pcore::WebSocket::pcore->accept(
                    $req,
                    compression   => $self->{compression},
                    on_disconnect => sub ($h) {

                        # node was destroyed
                        return if !defined $self;

                        $self->_on_node_disconnect($h);

                        return;
                    },
                    on_auth => sub ( $h, $token ) {

                        # node was destroyed
                        return if !defined $self;

                        ( $token, $h->{node_id}, $h->{node_type} ) = $token->@*;

                        # check authentication
                        if ( defined $self->{listen}->{username} && $token ne $self->{listen}->{username} ) {
                            $h->disconnect;

                            return;
                        }
                        else {
                            $self->_on_node_connect($h);

                            return res(200), $self->_get_bindings( $h->{node_type} );
                        }
                    },

                    # TODO
                    on_bind  => sub ( $h, $binding ) { return 1 },
                    on_event => $self->{_on_event},
                    on_rpc   => $self->{_on_rpc},
                );
            }

            return;
        }
    );

    return;
}

# TODO on_bind
sub _connect_node ( $self, $node_id, $check_connecting = 1 ) {
    state $can_connect_node = sub ( $self, $node_id, $check_connecting = 1 ) {

        # check, that node is known
        my $node = $self->{_nodes}->{$node_id};

        # return if node is unknown (was removed from nodes table)
        return if !defined $node;

        # node is already connected
        return if exists $self->{_all_conn}->{$node_id};

        return if $check_connecting && exists $self->{_conn_nodes}->{$node_id};

        # cyclic deps
        return if exists $node->{requires}->{ $self->{type} } && $self->{id} le $node_id;

        return $node;
    };

    my $node = $can_connect_node->( $self, $node_id, $check_connecting );

    # can't connect to the node
    return if !defined $node;

    $self->{_conn_nodes}->{$node_id} = 1;

    $node->{listen} = P->uri( $node->{listen}, base => 'ws:' ) if !is_ref $node->{listen};

    weaken $self;

    Coro::async_pool {
        my $h = Pcore::WebSocket::pcore->connect(
            $node->{listen},
            compression   => $self->{compression},
            pong_timeout  => $self->{pong_timeout},
            token         => [ $node->{listen}->{username}, $self->{id}, $self->{type} ],
            bindings      => $self->_get_bindings( $node->{type} ) // undef,
            node_id       => $node_id,
            node_type     => $node->{type},
            on_disconnect => sub ($h) {

                # node was destroyed
                return if !defined $self;

                $self->_on_node_disconnect($h);

                # can't connect to the node
                if ( !defined $can_connect_node->( $self, $node_id ) ) {
                    delete $self->{_conn_nodes}->{$node_id};

                    return;
                }

                # reconnect to node
                my $t;

                $t = AE::timer $self->{reconnect_timeout}, 0, sub {
                    undef $t;

                    # node was destroyed
                    return if !defined $self;

                    $self->_connect_node( $node_id, 0 );

                    return;
                };

                return;
            },

            # TODO
            on_bind  => sub ( $h, $binding ) { return 1 },
            on_event => $self->{_on_event},
            on_rpc   => $self->{_on_rpc},
        );

        delete $self->{_conn_nodes}->{$node_id};

        # connected to the node server
        $self->_on_node_connect($h) if $h;

        return;
    };

    return;
}

# NODE CONNECTION METHODS
sub _on_node_connect ( $self, $h ) {
    my $node_id   = $h->{node_id};
    my $node_type = $h->{node_type};

    # add connection if not already connected to this node id
    if ( !exists $self->{_all_conn}->{$node_id} ) {
        $self->{_all_conn}->{$node_id} = {
            id     => $node_id,
            type   => $node_type,
            status => $NODE_STATUS_UNKNOWN,
            h      => $h,
        };

        # required node was connected
        $self->_update($node_id) if exists $self->{requires}->{$node_type};
    }

    return;
}

sub _on_node_disconnect ( $self, $h ) {
    my $node_id = $h->{node_id};

    my $conn = delete $self->{_all_conn}->{$node_id};

    # required node was disconnected
    $self->_update($node_id) if $conn && exists $self->{requires}->{ $conn->{type} };

    return;
}

# NODE UPDATE METHODS
sub _on_node_register ( $self, $nodes ) {
    $self->{_nodes} = $nodes;

    $self->_update;

    return;
}

sub _on_node_add ( $self, $node ) {
    my $node_id = $node->{id};

    $self->{_nodes}->{$node_id} = $node;

    $self->_update($node_id);

    return;
}

sub _on_node_update ( $self, $node_id, $new_status ) {
    $self->{_nodes}->{$node_id}->{status} = $new_status;

    $self->_update($node_id);

    return;
}

sub _on_node_remove ( $self, $node_id ) {
    delete $self->{_nodes}->{$node_id};

    $self->_update($node_id);

    return;
}

sub _update ( $self, $node_id = undef ) {
    state $remove_conn = sub ( $self, $node_id, $node_type, $status ) {
        my $pool;

        if ( $status == $NODE_STATUS_READY ) {
            $pool = $self->{_ready_conn}->{$node_type};
        }
        elsif ( $status == $NODE_STATUS_ONLINE ) {
            $pool = $self->{_online_conn}->{$node_type};
        }
        else {
            return;
        }

        # remove node from online nodes
        for ( my $i = 0; $i <= $pool->$#*; $i++ ) {
            if ( $pool->[$i]->{node_id} eq $node_id ) {
                my $h = splice $pool->@*, $i, 1;

                # suspend events listener
                $h->suspend_events if $status == $NODE_STATUS_ONLINE;

                last;
            }
        }

        return;
    };

    state $check_wait_node = sub ( $self, $node_type ) {

        # has no pending "wait_node" callbacks for this type
        return if !exists $self->{_wait_node_cb}->{$node_type};

        my $online_nodes = $self->{_online_conn}->{$node_type};

        # has no online nodes of this type
        return if !$online_nodes || !$online_nodes->@*;

        # call pending callbacks
        for my $cb ( values delete( $self->{_wait_node_cb}->{$node_type} )->%* ) { $cb->() }

        return;
    };

    state $update_node = sub ( $self, $node_id ) {
        my $node = $self->{_nodes}->{$node_id};
        my $conn = $self->{_all_conn}->{$node_id};

        # hmm.., nothing to do
        return if !defined $conn && !defined $node;

        # node was added OR disconnected
        if ( !defined $conn && defined $node ) {

            # remove connection from the corresponded pool
            $remove_conn->( $self, $node_id, $node->{type}, $node->{status} );

            $self->_connect_node($node_id);
        }

        # node was removed from nodes table, remove node connection
        elsif ( defined $conn && !defined $node ) {
            my $node_type = $conn->{type};
            my $status    = $conn->{status};

            delete $self->{_all_conn}->{$node_id};

            # remove connection from the corresponded pool
            $remove_conn->( $self, $node_id, $node_type, $status );
        }

        # connection to the node established
        # synchronize node status
        else {
            my $node_type  = $node->{type};
            my $old_status = $conn->{status};
            my $new_status = $node->{status};

            # synchronize status
            $conn->{status} = $new_status;

            # remove connection from the corresponded pool
            $remove_conn->( $self, $node_id, $node_type, $old_status );

            # add connection to the corresponded pool
            if ( $new_status == $NODE_STATUS_READY ) {
                unshift $self->{_ready_conn}->{$node_type}->@*, $conn->{h};
            }
            elsif ( $new_status == $NODE_STATUS_ONLINE ) {
                unshift $self->{_online_conn}->{$node_type}->@*, $conn->{h};

                # enable event listeners
                $conn->{h}->resume_events;

                # check "wait_node" status changes
                $check_wait_node->( $self, $node_type );
            }
        }

        return;
    };

    if ( defined $node_id ) {
        $update_node->( $self, $node_id );
    }
    else {
        for my $node_id ( keys $self->{_nodes}->%* ) { $update_node->( $self, $node_id ) }
    }

    # do nothing if in OFFLINE
    return if $self->{status} == $NODE_STATUS_OFFLINE;

    # calc new node status
    my $new_status = $self->_get_status;

    # update node status
    $self->_set_status($new_status);

    return;
}

sub _get_status ($self) {

    # node status is ONLINE if node has no requirements
    return $NODE_STATUS_ONLINE if !$self->{_has_requires};

    my $max_type_status = {};

    for my $conn ( values $self->{_all_conn}->%* ) {

        # skip not-required nodes
        next if !exists $self->{requires}->{ $conn->{type} };

        # find max. status for each established conn. type
        $max_type_status->{ $conn->{type} } = $conn->{status} if $conn->{status} > ( $max_type_status->{ $conn->{type} } //= -1 );
    }

    # check, that all required connections types are established
    # CONNECTING if total establised conns. types < total number of required conns.
    return $NODE_STATUS_CONNECTING if $max_type_status->%* < $self->{requires}->%*;

    # find minimal common status of all required connections
    my $min_status = P->list->min( values $max_type_status->%* ) // -1;

    return $NODE_STATUS_ONLINE if $min_status >= $NODE_STATUS_READY;

    return $NODE_STATUS_READY if $min_status == $NODE_STATUS_CONNECTED;

    return $NODE_STATUS_CONNECTED;
}

sub _set_status ( $self, $new_status ) {
    my $old_status = $self->{status};

    return if $old_status == $new_status;

    $self->{status} = $new_status;

    # update status on server
    if ( defined $self->{server} && $self->{server_is_online} ) {
        if ( $self->{_server_is_remote} ) { $self->{_remote_server_h}->rpc_call( 'update_status', $new_status ) }
        else                              { $self->{server}->update_node_status( $self->{id}, $new_status ) }
    }

    # call "on_status" callback
    $self->{on_status}->( $self, $new_status, $old_status ) if $self->{on_status};

    if ( $new_status != $NODE_STATUS_ONLINE ) {
        $self->{is_online} = 0;
    }
    else {
        $self->{is_online} = 1;

        # status was changed to "online" and has "wait_online" callbacks
        if ( $self->{_wait_online_cb} ) {

            # call pending "wait_for_online" callbacks
            for my $cb ( values delete( $self->{_wait_online_cb} )->%* ) { $cb->() }
        }
    }

    return;
}

# ONLINE / OFFLINE METHODS
sub go_online ($self) {
    return if $self->{status} != $NODE_STATUS_OFFLINE;

    my $new_status = $self->_get_status;

    $self->_set_status($new_status);

    return;
}

sub go_offline ($self) {
    return if $self->{status} == $NODE_STATUS_OFFLINE;

    $self->_set_status($NODE_STATUS_OFFLINE);

    return;
}

# BLOCKING METHODS
sub online_nodes ( $self, $type ) {
    return 0 if !$self->{_online_conn}->{$type};

    return scalar $self->{_online_conn}->{$type}->@*;
}

sub wait_online ( $self, $timeout = undef ) {
    return 1 if $self->{is_online};

    my $cv = P->cv;

    my $id = refaddr $cv;

    $self->{_wait_online_cb}->{$id} = $cv;

    # set timer if has $timeout
    my $t;

    if ( $timeout //= $self->{wait_online_timeout} ) {
        $t = AE::timer $timeout, 0, sub {

            # node was destroyed
            return if !defined $self;

            # remove and call callback
            ( delete $self->{_wait_online_cb}->{$id} )->();

            return;
        };
    }

    $cv->recv;

    return $self->{is_online};
}

sub wait_node ( $self, $type, $timeout = undef ) {

    # only required nodes can be monitored
    return 0 if !$self->{_has_requires} || !exists $self->{requires}->{$type};

    my $online_nodes = $self->online_nodes($type);

    return $online_nodes if $online_nodes;

    my $cv = P->cv;

    my $id = refaddr $cv;

    $self->{_wait_node_cb}->{$type}->{$id} = $cv;

    # set timer if has $timeout
    my $t;

    if ( $timeout //= $self->{wait_online_timeout} ) {
        $t = AE::timer $timeout, 0, sub {

            # node was destroyed
            return if !defined $self;

            # remove and call callback
            ( delete $self->{_wait_node_cb}->{$type}->{$id} )->();

            return;
        };
    }

    $cv->recv;

    return $self->online_nodes($type);
}

# required for run node via run_proc interface
sub import {
    if ( $0 eq '-' ) {
        state $init;

        return if $init;

        $init = 1;

        my ( $self, $type ) = @_;

        # read and unpack boot args from STDIN
        my $BOOT_ARGS = <>;

        chomp $BOOT_ARGS;

        require CBOR::XS;

        $BOOT_ARGS = CBOR::XS::decode_cbor( pack 'H*', $BOOT_ARGS );

        # init RPC environment
        $Pcore::SCRIPT_PATH = $BOOT_ARGS->{script_path};
        $main::VERSION      = version->new( $BOOT_ARGS->{version} );
        $ENV->set_scandeps( $BOOT_ARGS->{scandeps} );

        require Pcore::Node::Node;

        require $type =~ s[::][/]smgr . '.pm';

        Pcore::Node::Node::run( $type, $BOOT_ARGS );

        exit;
    }

    return;
}

sub run_node ( $self, @nodes ) {
    my $cv = P->cv->begin;

    weaken $self;

    my $server = do {
        if ( ref $self->{server} eq 'Pcore::Node::Server' ) {
            $self->{server}->{listen};
        }
        else {
            $self->{server};
        }
    };

    for my $node (@nodes) {

        # resolve number of the workers
        $node->{workers} = P->sys->cpus_num( $node->{workers} );

        # run workers
        for ( 1 .. $node->{workers} ) {
            $cv->begin;

            Coro::async_pool {
                my $node_proc = Pcore::Node::Proc->new(
                    $node->{type},
                    server    => $node->{server} // $server,
                    listen    => $node->{listen},
                    buildargs => $node->{buildargs},
                    on_finish => sub ($proc) {
                        return if !defined $self;

                        delete $self->{_node_proc}->{ refaddr $proc };

                        return;
                    }
                );

                $self->{_node_proc}->{ refaddr $node_proc} = $node_proc;

                $cv->end;

                return;
            };
        }
    }

    $cv->end->recv;

    return res 200;
}

# TODO repeat to other node if node returns 1013 Try Again Later
sub rpc_call ( $self, $type, $method, @args ) {
    my $h = shift $self->{_online_conn}->{$type}->@*;

    if ( defined $h ) {
        push $self->{_online_conn}->{$type}->@*, $h;
    }
    else {
        $h = shift $self->{_ready_conn}->{$type}->@*;

        push $self->{_ready_conn}->{$type}->@*, $h if defined $h;
    }

    return res [ 404, qq[Node type "$type" is not available] ] if !defined $h;

    return $h->rpc_call( $method, @args );
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitUnusedPrivateSubroutines                                                                  |
## |      | 430                  | * Private subroutine/method '_on_node_register' declared but not used                                          |
## |      | 438                  | * Private subroutine/method '_on_node_add' declared but not used                                               |
## |      | 448                  | * Private subroutine/method '_on_node_update' declared but not used                                            |
## |      | 456                  | * Private subroutine/method '_on_node_remove' declared but not used                                            |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 464                  | Subroutines::ProhibitExcessComplexity - Subroutine "_update" with high complexity score (24)                   |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 479                  | ControlStructures::ProhibitCStyleForLoops - C-style "for" loop used                                            |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Node

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
