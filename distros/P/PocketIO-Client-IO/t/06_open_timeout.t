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

{
    no warnings;

    my $orig_func = \&PocketIO::Resource::_build_transport;

    *PocketIO::Resource::_build_transport = sub {
        sleep (3);
        return $orig_func->(@_);
    };
}

my $app = builder {
    mount '/socket.io' => PocketIO->new(
        handler => sub {
            my $self = shift;
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
    my $client = AnyEvent::PocketIO::Client->new( open_timeout => 1 );    

    isa_ok( $client, 'AnyEvent::PocketIO::Client' );

    my $cv  = AnyEvent->condvar;

    $client->handshake( $server, $port, sub {
        my ( $error, $self, $sesid, $hbtimeout, $contimeout, $transports ) = @_;

        ok( $sesid, sprintf("handshake : %s,%s,%s", $sesid, $hbtimeout, $contimeout) );

        $client->open( 'websocket' => sub {
            my ( $error, $self ) = @_;

            if ( $error ) {
                is( $error->{ message }, 'Open timeout.' );
                $cv->send;
                return;
            }

            fail('socket opend');

            $cv->send;
        });

    } );

    $cv->wait;
   
    ok(1, 'test end');
}

done_testing;



