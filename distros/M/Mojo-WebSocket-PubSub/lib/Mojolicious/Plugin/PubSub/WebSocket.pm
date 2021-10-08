package Mojolicious::Plugin::PubSub::WebSocket;
$Mojolicious::Plugin::PubSub::WebSocket::VERSION = '0.04';
# ABSTRACT: Plugin to implement PubSub protocol using websocket

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::WebSocket::PubSub::Syntax;

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
            $c->on( json => sub { $syn->parse( $_[1] ); } );
            $c->on(
                finish => sub {
                    my ( $c, $code, $reason ) = @_;
                    my $id     = $c->tx->connection;
                    return unless $c->isa('psws_clients');
                    my $client = $c->psws_clients->{$id};
                    delete $c->psws_channels->{ $client->{channel} }->{$id}
                      if ( exists $client->{channel} );
                    delete $c->psws_clients->{$id};
                    $c->app->log->debug( "PSWS: WebSocket "
                          . $c->tx->connection
                          . " closed with status $code" );
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
        $c->psws_channels->{$ch}->{$id} = 1;
        $c->psws_clients->{$id}->{channel} = $ch;
    }
    if ( my $res_f = $syn->lookup->{ $req->{t} }->{reply} ) {
        my $res = $res_f->( $req, $id );
        if ( $event eq 'notify' ) {
            my $msg = $req->{msg};
            my $ch  = $c->psws_clients->{$id}->{channel};
            foreach
              my $client ( grep !/$id/, keys %{$c->psws_channels->{$ch}} )
            {
                $c->psws_clients->{$client}->{tx}->send( { json => $res } );
            }
            # now reply to sender
            $res = $syn->notified($req);
        }
        $c->tx->send( { json => $res } );
    }
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::PubSub::WebSocket - Plugin to implement PubSub protocol using websocket

=head1 VERSION

version 0.04

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
