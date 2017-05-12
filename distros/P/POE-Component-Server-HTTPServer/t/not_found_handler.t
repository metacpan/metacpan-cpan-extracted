use Test::More tests => 9;

use HTTP::Status;
use HTTP::Response;

BEGIN { 
  use_ok('POE::Component::Server::HTTPServer');
  use_ok('POE::Component::Server::HTTPServer::Handler');
  use_ok('POE::Component::Server::HTTPServer::NotFoundHandler');
};

my $h = new_handler( 'NotFoundHandler' );
ok( defined($h), 'constructor returns defined' );
isa_ok( $h, 'POE::Component::Server::HTTPServer::Handler' );
can_ok( $h, 'handle' );
my $h2 = new_handler( 'NotFoundHandler' );
ok( $h==$h2, 'NFH is a singleton' );

my $resp = HTTP::Response->new( RC_OK );
my $retval = $h->handle( { response => $resp } );
ok( $retval == H_FINAL, 'Handler finalized response' );
ok( $resp->code == RC_NOT_FOUND, 'Response has correct code' );


