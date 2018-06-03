package Pcore::Node::Server;

use Pcore -class, -res;
use Pcore::Util::UUID qw[uuid_v4_str];
use Pcore::WebSocket::pcore;
use Pcore::HTTP::Server;
use Pcore::Node::Const qw[:ALL];

has token => sub {uuid_v4_str};
has listen => ();

has _node         => ();    # all nodes
has _client_node  => ();    # client nodes
has _service_node => ();    # service nodes

sub run ($self) {
    $self->{listen} = P->net->resolve_listen( $self->{listen} );

    $self->{http_server} = Pcore::HTTP::Server->new( {
        listen => $self->{listen},
        app    => sub ($req) {
            if ( $req->is_websocket_connect_request ) {

                # create connection, accept websocket connect request
                Pcore::WebSocket::pcore->new(
                    compression   => 0,
                    on_disconnect => sub ( $h, $status ) {
                        $self->_on_node_disconnect( $h->{_node_id} );

                        return;
                    },
                    on_auth => sub ( $h, $token, $cb ) {
                        ( my $id, $token ) = $token->@*;

                        if ( $self->{token} && $self->{token} ne ( $token // q[] ) ) {
                            $h->disconnect( res 401 );

                            return;
                        }

                        $h->{_node_id} = $id;

                        $cb->( res(200), forward => 'SWARM' );

                        return;
                    },
                    on_subscribe => sub ( $h, $event ) {
                        return;
                    },
                    on_event => sub ( $h, $ev ) {
                        return;
                    },
                    on_rpc => sub ( $h, $req, $tx ) {
                        $self->_on_rpc( $h->{_node_id}, $req, $tx );

                        return;
                    },
                )->accept($req);
            }
            else {
                $req->return_xxx(400);
            }

            return;
        },
    } );

    $self->{http_server}->run;

    return $self;
}

sub _on_rpc ( $self, $node_id, $req, $tx ) {

    # register node
    if ( $tx->{method} eq 'register' ) {
        my $node = $tx->{args}->[0];

        if ( $node->{is_service} ) {
            $self->{_node}->{$node_id} = $self->{_service_node}->{$node_id} = $node;
        }
        else {
            $self->{_node}->{$node_id} = $self->{_client_node}->{$node_id} = $node;
        }

        P->fire_event( 'SWARM', $node ) if $node->{status} == $STATUS_ONLINE;

        # return full service_node table
        $req->( res 200, [ values $self->{_service_node}->%* ] );
    }

    # update node status
    elsif ( $tx->{method} eq 'update' ) {
        $self->_set_node_status( $node_id, $tx->{args}->[0]->{status} );
    }

    return;
}

sub _on_node_disconnect ( $self, $node_id ) {
    my $node = delete $self->{_node}->{$node_id};

    if ( $node->{is_service} ) {
        delete $self->{_service_node}->{$node_id};

        if ( $node->{status} == $STATUS_ONLINE ) {
            $node->{status} = $STATUS_OFFLINE;

            P->fire_event( 'SWARM', $node );
        }
    }
    else {
        delete $self->{_client_node}->{$node_id};
    }

    return;
}

sub _set_node_status ( $self, $node_id, $new_status ) {
    my $node = $self->{_node}->{$node_id};

    my $current_status = $node->{status};

    if ( $current_status != $new_status ) {
        $node->{status} = $new_status;

        P->fire_event( 'SWARM', $node ) if $node->{is_service};
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Node::Server

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
