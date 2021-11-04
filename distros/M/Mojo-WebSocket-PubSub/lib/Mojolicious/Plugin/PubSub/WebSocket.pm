package Mojolicious::Plugin::PubSub::WebSocket;
$Mojolicious::Plugin::PubSub::WebSocket::VERSION = '0.06';
# ABSTRACT: Plugin to implement PubSub protocol using websocket

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::WebSocket::PubSub::Syntax;
use DDP;

sub register {
    my ( $s, $app, $conf ) = @_;
    $app->log->debug( "Loading " . __PACKAGE__ );

    my $r = $app->routes;

    $app->helper( psws_clients  => sub { state $clients  = {} } );
    $app->helper( psws_channels => sub { state $channels = {} } );

    $r->websocket('/psws')->to(
        cb => sub {
            my $c   = shift;
            my $syn = new Mojo::WebSocket::PubSub::Syntax;
            $syn->on( 'all' => sub { $s->psws_reply( $c, @_ ) } );
            $c->on(
                json => sub {
                    $app->log->debug(
                        sprintf( "RCV from %s: %s",
                            $c->tx->connection, np $_[1] )
                    );
                    $syn->parse( $_[1] );
                }
            );
            $c->on(
                finish => sub {
                    my ( $c, $code, $reason ) = @_;
                    my $id = $c->tx->connection;
                    $c->app->log->debug(
                        "PSWS: WebSocket $id" . " closed with status $code" );
                    return unless exists $c->psws_clients->{$id};
                    my $client = $c->psws_clients->{$id};
                    if ( exists $client->{channel} ) {
                        $c->app->log->debug( "PSWS: WebSocket $id removed from "
                              . "channel " . $client->{channel} );
                        delete $c->psws_channels->{ $client->{channel} }->{$id};
                    }
                    delete $c->psws_clients->{$id};
                },
            );

            $s->connected($c);
        }
    );
}

sub connected {
    my $s  = shift;
    my $c  = shift;
    my $id = $c->tx->connection;
    $c->app->log->debug("PSWS: New connection from $id");
    $c->psws_clients->{$id} = { tx => $c->tx };
}

sub psws_reply {
    my ( $s, $c, $syn, $event, $req ) = @_;
    my $id = $c->tx->connection;
    $req->{id} = $id;

    if ( $event eq 'listen' ) {
        my $ch = $req->{ch};
        return unless $ch;
        # leave previous channel if exists
        my $pch = $c->psws_clients->{$id}->{channel};
        delete $c->psws_channels->{$pch}->{$id} if $pch;
        $c->psws_channels->{$ch}->{$id} = 1;
        $c->psws_clients->{$id}->{channel} = $ch;
    }
    if ( my $res_f = $syn->lookup->{ $req->{t} }->{reply} ) {
        my $res = $res_f->( $req, $id );
        if ( $event eq 'notify' ) {
            my $msg = $req->{msg};
            my $ch  = $c->psws_clients->{$id}->{channel};
            foreach
              my $client ( grep !/$id/, keys %{ $c->psws_channels->{$ch} } )
            {
                $c->app->log->debug(
                    sprintf( 'SNT to %s: %s', $client, np $res) );
                $c->psws_clients->{$client}->{tx}->send( { json => $res } );
            }

            # now reply to sender
            $res = $syn->notified($req);
        }
        $c->app->log->debug( sprintf( 'SNT to %s: %s', $id, np $res) );
        $c->tx->send( { json => $res } );
    }
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::PubSub::WebSocket - Plugin to implement PubSub protocol using websocket

=head1 VERSION

version 0.06

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
