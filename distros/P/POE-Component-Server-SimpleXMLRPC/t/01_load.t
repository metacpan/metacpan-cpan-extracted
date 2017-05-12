use Test::More tests => 3;
use_ok( 'POE::Component::Server::SimpleXMLRPC' );
use_ok( 'Frontier::RPC2' );
use_ok( 'Encode' );
diag( "Testing POE::Component::Server::SimpleXMLRPC-$POE::Component::Server::SimpleXMLRPC::VERSION, POE-$POE::VERSION, Perl $], $^X" );
