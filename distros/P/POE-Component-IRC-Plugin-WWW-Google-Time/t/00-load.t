#!/usr/bin/env perl

use Test::More tests => 4;

BEGIN {
    use_ok('POE');
    use_ok('POE::Component::IRC::Plugin::BasePoCoWrap');
    use_ok('POE::Component::WWW::Google::Time');
	use_ok( 'POE::Component::IRC::Plugin::WWW::Google::Time' );
}

diag( "Testing POE::Component::IRC::Plugin::WWW::Google::Time $POE::Component::IRC::Plugin::WWW::Google::Time::VERSION, Perl $], $^X" );
