#!/usr/bin/env perl

use Test::More tests => 4;

BEGIN {
	use_ok( 'POE::Component::WWW::Google::Time' );
    use_ok('POE');
    use_ok('WWW::Google::Time');
    use_ok('POE::Component::NonBlockingWrapper::Base');   
}

diag( "Testing POE::Component::WWW::Google::Time $POE::Component::WWW::Google::Time::VERSION, Perl $], $^X" );
