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

    my $orig_func = \&PocketIO::Resource::_dispatch_handshake;

    *PocketIO::Resource::_dispatch_handshake = sub {
        sleep (5);
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
    my $client = AnyEvent::PocketIO::Client->new( handshake_timeout => 2 );

    my $cv  = AnyEvent->condvar;

    $client->handshake( $server, $port, sub {
        my ( $error, $self ) = @_;
        ok( $error, "error" );
        is_deeply( $error, { code => 500, message => 'Handshake timeout.' } );
        $cv->send;
    } );

    $cv->wait;
}

done_testing;



