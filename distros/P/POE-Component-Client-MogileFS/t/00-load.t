#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'POE::Component::Client::MogileFS' );
}

diag( "Testing POE::Component::Client::MogileFS $POE::Component::Client::MogileFS::VERSION, Perl $], $^X" );
