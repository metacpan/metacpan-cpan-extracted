#!/usr/bin/env perl

use Test::More tests => 4;

BEGIN {
    use_ok('POE');
    use_ok('POE::Component::NonBlockingWrapper::Base');
    use_ok('WWW::CPANRatings::RSS');
	use_ok( 'POE::Component::WWW::CPANRatings::RSS' );
}

diag( "Testing POE::Component::WWW::CPANRatings::RSS $POE::Component::WWW::CPANRatings::RSS::VERSION, Perl $], $^X" );
