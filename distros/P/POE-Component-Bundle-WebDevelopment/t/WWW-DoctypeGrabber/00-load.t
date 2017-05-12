#!/usr/bin/env perl

use Test::More tests => 4;

BEGIN {
    use_ok('POE');
    use_ok('POE::Component::NonBlockingWrapper::Base');
    use_ok('WWW::DoctypeGrabber');
	use_ok( 'POE::Component::WWW::DoctypeGrabber' );
}

diag( "Testing POE::Component::WWW::DoctypeGrabber $POE::Component::WWW::DoctypeGrabber::VERSION, Perl $], $^X" );
