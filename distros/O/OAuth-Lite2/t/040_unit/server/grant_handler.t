use strict;
use warnings;

use Test::More; 
use OAuth::Lite2::Server::GrantHandler;

use lib 't/lib';
use TestDataHandler;

my $handler = OAuth::Lite2::Server::GrantHandler->new;
ok( $handler, q{new});

ok( $handler->is_required_client_authentication, q{client_authentication});

my $dh = TestDataHandler->new;
eval {
    $handler->handle_request( $dh );
};
my $error = $@;
like( $error, qr/abstract method/, q{handle_request});

done_testing;
