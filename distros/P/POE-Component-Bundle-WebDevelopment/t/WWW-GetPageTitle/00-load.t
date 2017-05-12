#!/usr/bin/env perl

use Test::More tests => 4;

BEGIN {
	use_ok( 'POE::Component::WWW::GetPageTitle' );
    use_ok('POE');
    use_ok('POE::Component::NonBlockingWrapper::Base');
    use_ok('WWW::GetPageTitle');
}

diag( "Testing POE::Component::WWW::GetPageTitle $POE::Component::WWW::GetPageTitle::VERSION, Perl $], $^X" );
