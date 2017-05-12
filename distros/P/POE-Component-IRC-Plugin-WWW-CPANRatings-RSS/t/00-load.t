#!/usr/bin/env perl

use Test::More tests => 5;

BEGIN {
    use_ok('POE');
    use_ok('POE::Component::WWW::CPANRatings::RSS');
    use_ok('POE::Component::IRC::Plugin');
    use_ok('utf8');
	use_ok( 'POE::Component::IRC::Plugin::WWW::CPANRatings::RSS' );
}

diag( "Testing POE::Component::IRC::Plugin::WWW::CPANRatings::RSS $POE::Component::IRC::Plugin::WWW::CPANRatings::RSS::VERSION, Perl $], $^X" );
