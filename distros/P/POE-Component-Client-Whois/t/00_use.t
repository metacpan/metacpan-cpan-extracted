use Test::More tests => 1;

BEGIN {
	use_ok( 'POE::Component::Client::Whois' );
}

diag( "Testing POE::Component::Client::Whois $POE::Component::Client::Whois::VERSION, POE $POE::VERSION, Perl $], $^X" );
