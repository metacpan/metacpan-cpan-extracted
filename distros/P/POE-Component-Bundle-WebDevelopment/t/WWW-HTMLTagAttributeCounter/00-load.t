#!/usr/bin/env perl

use Test::More tests => 4;

BEGIN {
    use_ok('POE');
    use_ok('POE::Component::NonBlockingWrapper::Base');
    use_ok('WWW::HTMLTagAttributeCounter');
	use_ok( 'POE::Component::WWW::HTMLTagAttributeCounter' );
}

diag( "Testing POE::Component::WWW::HTMLTagAttributeCounter $POE::Component::WWW::HTMLTagAttributeCounter::VERSION, Perl $], $^X" );
