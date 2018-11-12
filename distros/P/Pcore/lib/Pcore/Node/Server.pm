package Pcore::Node::Server;

use Pcore -class, -res;
use Pcore::Util::Scalar qw[weaken];
use Pcore::Util::UUID qw[uuid_v4_str];
use Pcore::HTTP::Server;
use Pcore::WebSocket::pcore;
use Clone qw[clone];

has listen      => ();
has compression => 0;

has id           => ( sub {uuid_v4_str}, init_arg => undef );
has token        => ( init_arg                    => undef );    # take from listen or generste
has _http_server => ( init_arg                    => undef );    # InstanceOf['Pcore::HTTP::Server']
has _nodes       => ( init_arg                    => undef );    # HashRef, node registry, node_id => {}
has _nodes_h     => ( init_arg                    => undef );    # HashRef, connected nodes handles, node_id => $handle

sub BUILD ( $self, $args ) {
    weaken $self;

    $self->{_http_server} = Pcore::HTTP::Server->new(
        listen     => $self->{listen},
        on_request => sub ($req) {
            if ( $req->is_websocket_connect_request ) {
                my $h = Pcore::WebSocket::pcore->accept(
                    $req,
                    compression   => $self->{compression},
                    on_disconnect => sub ($h) {
                        return if !defined $self;

                        $self->remove_node( $h->{node_id} );

                        return;
                    },
                    on_auth => sub ( $h, $token ) {
                        return if !defined $self;

                        ( $token, $h->{node_id}, $h->{node_data} ) = $token->@*;

                        if ( $self->{token} && $token ne $self->{token} ) {
                            $h->disconnect;

                            return;
                        }
                        else {
                            return res 200;
                        }
                    },
                    on_ready => sub ($h) {
                        $self->register_node( $h, $h->{node_id}, delete $h->{node_data}, 1 );

                        return;
                    },
                    on_rpc => sub ( $h, $req, $tx ) {
                        return if !defined $self;

                        if ( $tx->{method} eq 'update_status' ) {
                            $self->update_node_status( $h->{node_id}, $tx->{args}->[0] );
                        }

                        return;
                    },
                );
            }

            return;
        }
    );

    $self->{listen} = $self->{_http_server}->{listen};

    $self->{listen}->set_username(uuid_v4_str) if !defined $self->{listen}->{username};

    return;
}

sub register_node ( $self, $node_h, $node_id, $node_data, $is_remote = 0 ) {
    my $node = $self->{_nodes}->{$node_id} = $node_data;

    my $requires = $node->{requires} //= {};

    $self->{_nodes_h}->{$node_id} = {
        id        => $node_id,
        requires  => $requires,
        is_remote => $is_remote,
        h         => $node_h,
    };

    weaken $self->{_nodes_h}->{$node_id}->{h};

    # prepare nodes table for send, only if registered node have requires
    if ( $requires->%* ) {
        my $tbl = clone $self->{_nodes};

        # remove this node from nodes table
        delete $tbl->{$node_id};

        # remove not required nodes
        for my $id ( keys $tbl->%* ) {
            delete $tbl->{$id} if !exists $requires->{ $tbl->{$id}->{type} };
        }

        $self->_send_rpc( $self->{_nodes_h}->{$node_id}, '_on_node_register', [$tbl] ) if $tbl->%*;
    }

    # send this node to all other registered nodes
    $self->_on_update( '_on_node_add', $node, clone $node );

    return;
}

sub remove_node ( $self, $node_id ) {
    if ( exists $self->{_nodes}->{$node_id} ) {
        my $node = delete $self->{_nodes}->{$node_id};

        delete $self->{_nodes_h}->{$node_id};

        $self->_on_update( '_on_node_remove', $node, $node_id );
    }

    return;
}

sub update_node_status ( $self, $node_id, $status ) {
    my $node = $self->{_nodes}->{$node_id};

    # node is unknown
    return if !defined $node;

    # node status was changed
    if ( $node->{status} != $status ) {
        $node->{status} = $status;

        $self->_on_update( '_on_node_update', $node, $node_id, $status );
    }

    return;
}

sub _on_update ( $self, $method, $updated_node, @data ) {
    my $updated_node_id   = $updated_node->{id};
    my $updated_node_type = $updated_node->{type};

    for my $node ( values $self->{_nodes_h}->%* ) {

        # do not send updates to myself
        next if $node->{id} eq $updated_node_id;

        # do not send updates, if node is not required
        next if !exists $node->{requires}->{$updated_node_type};

        $self->_send_rpc( $node, $method, \@data );
    }

    return;
}

sub _send_rpc ( $self, $node, $method, $data ) {

    # remote node
    if ( $node->{is_remote} ) {
        $node->{h}->rpc_call( $method, $data->@* );
    }

    # local node
    else {
        $node->{h}->$method( $data->@* );
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 78                   | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
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
