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
my $foo = 1;
my $app = builder {
    mount '/socket.io' => PocketIO->new(
        handler => sub {
            my $self = shift;
            $self->on('foo' => sub {
                ok(1, "server recieved message from " . $_[1]);
                $self->sockets->send('foo ' . $foo++);
            } );
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
    my $client2 = AnyEvent::PocketIO::Client->new;    

    my $cv    = AnyEvent->condvar;
    my $hb    = 0;
    my $hb_cb = sub {
        if ( ++$hb > 2 ) { # all cancel
            diag("many hearbeat");
            $cv->end;
        }
    };
    $client ->on( 'heartbeat' => $hb_cb );
    $client2->on( 'heartbeat' => $hb_cb );

    my $create_cb = sub {
        my $num = shift;
        return sub {
            my ( $error, $self, $sesid, $hbtimeout, $contimeout, $transports ) = @_;

            if ( $error ) {
                fail(Dumper($error));
                return $cv->end;
            }

            ok( $sesid, sprintf("handshake %d : %s,%s,%s", $num, $sesid, $hbtimeout, $contimeout) );

            $self->on( 'message' => sub {
                ok( 1, "$num get message $_[1]" );
            } );

            $self->open( 'websocket' => sub {
                my ( $error, $self ) = @_;
                ok(1, sprintf('socket opened %d', $num));
                $self->emit('foo', $num);
                $cv->end;
            } );

        };
    };

    $cv->begin;
    $client->handshake( $server, $port, $create_cb->(1) );

    $cv->begin;
    $client2->handshake( $server, $port, $create_cb->(2) );

    $cv->begin;
    my $w; $w = AnyEvent->timer( after => 5, cb => sub {
        $cv->end;
        undef $w;        
    });
    $cv->wait;

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
    if ( $client2->is_opened ) {
        $cv3->begin;
        $client2->disconnect;
    }

    $cv3->wait;
   
    ok(1, 'test end');
}

done_testing;



