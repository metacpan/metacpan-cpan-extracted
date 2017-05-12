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

package Test::PocketIO::Error;

use strict;
use base 'PocketIO';

my $error_test_num = 1;

sub call {
    my ($env) = @_;
    my $response;

    do {
        my $e = $error_test_num++ == 1
                     ? "error" : PocketIO::Exception->new( code => 503, message => "Uguu" );

        require Scalar::Util;
        die $e unless Scalar::Util::blessed($e);

        my $code = $e->code;
        my $message = $e->message || 'Internal Server Error';

        my @headers = (
            'Content-Type'   => 'text/plain',
            'Content-Length' => length($message),
        );

        $response = [$code, \@headers, [$message]];
    };

    return $response;
}


package main;

my $app = builder {
    mount '/socket.io' => Test::PocketIO::Error->new(
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
    my $client = AnyEvent::PocketIO::Client->new;    

    isa_ok( $client, 'AnyEvent::PocketIO::Client' );

    my $cv  = AnyEvent->condvar;

    $client->handshake( $server, $port, sub {
        my ( $error, $self ) = @_;
        ok( $error, "500 error" );
        is( $error->{ code }, 500, 'code 500' );
        $cv->send;
    } );

    $cv->wait;

    my $cv2  = AnyEvent->condvar;

    $client->handshake( $server, $port, sub {
        my ( $error, $self ) = @_;
        ok( $error, "503 error" );
        is( $error->{ code }, 503, 'code 503' );
        $cv2->send;
    } );

    $cv2->wait;


    $client->on( 'disconnect' => sub {
        ok(1, 'disconnect');
    });

    $client->on( 'close' => sub {
        ok(1, 'socket closed');
    });

}

done_testing;



