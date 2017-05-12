use strict;
use warnings;

BEGIN {
    use Test::More;
    plan skip_all => 'Plack and Twiggy are required to run this test'
      unless eval { require Plack; require Twiggy; 1 };
}

use PocketIO::Test;

use AnyEvent;
use Plack::Builder;
use PocketIO;
use Data::Dumper;

use AnyEvent::PocketIO::Client;

my $app = builder {
    mount '/socket.io' => PocketIO->new(
        handler => sub {
            my $self = shift;
            $self->on('message' => sub {
                ok(1, "server recieved message. " . $_[1]);
            } );
            $self->on('hello' => sub {
                my ( $self, @data ) = @_;
                ok(1, "server hello");
                $self->send("hello, $data[0]");
            });
            $self->on('foo' => sub {
                my ( $self, @data ) = shift;
                ok(1, "server foo");
                $self->emit('bar');
            });
            ok(1, 'server handler runs');
        }
    );
};


my $server = '127.0.0.1';


test_pocketio(
    $app => \&_test
);

sub _test {
    my $port   = shift;
    my $client = AnyEvent::PocketIO::Client->new;    

    isa_ok( $client, 'AnyEvent::PocketIO::Client' );

    my $cv  = AnyEvent->condvar;

    my $hb  = 0;
    $client->on( 'heartbeat' => sub {
        if ( ++$hb > 1 ) { # all cancel
            diag("many hearbeat");
            $cv->send;
        }
    });

    $client->handshake( $server, $port, sub {
        my ( $error, $self, $sesid, $hbtimeout, $contimeout, $transports ) = @_;

        if ( $error ) {
            fail('handshake');
            return $cv->send;
        }

        ok( $sesid, sprintf("handshake 1 : %s,%s,%s", $sesid, $hbtimeout, $contimeout) );

        $self->open( 'websocket' => sub {
            my ( $error, $self ) = @_;
            ok(1, 'socket opened 1');
            $cv->send;
        });

    } );

    $cv->wait;

    my $cv2 = AnyEvent->condvar;
    my $client2 = AnyEvent::PocketIO::Client->new;    

    my $hb2  = 0;
    $client2->on( 'heartbeat' => sub {
        if ( ++$hb2 > 1 ) { # all cancel
            diag("many hearbeat");
            $cv2->send;
        }
    });

    $client2->handshake( $server, $port, sub {
        my ( $error, $self, $sesid, $hbtimeout, $contimeout, $transports ) = @_;

        if ( $error ) {
            fail('handshake');
            return $cv2->send;
        }

        ok( $sesid, sprintf("handshake 2 : %s,%s,%s", $sesid, $hbtimeout, $contimeout) );

        $self->open( 'websocket' => sub {
            my ( $error, $self ) = @_;
            ok(1, 'socket opened 2');
            $cv2->send;
        });

    } );

    $cv2->wait;

    my $cv3 = AnyEvent->condvar;

    $client->on( 'disconnect' => sub {
        ok(1, 'disconnect 1');
        $cv3->end;
    });
    $client2->on( 'disconnect' => sub {
        ok(1, 'disconnect 2');
        $cv3->end;
    });

    if ( $client->is_opened ) {
        $cv3->begin;
        $client->disconnect;
    }
    if ( $client->is_opened ) {
        $cv3->begin;
        $client2->disconnect;
    }

    $cv3->wait;
   
    ok(1, 'test end');
}

done_testing;



