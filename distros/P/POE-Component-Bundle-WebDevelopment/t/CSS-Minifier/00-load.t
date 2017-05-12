#!/usr/bin/env perl

use Test::More tests => 6;

BEGIN {
    use_ok('Carp');
    use_ok('POE');
    use_ok('POE::Component::NonBlockingWrapper::Base');
    use_ok('CSS::Minifier');
    use_ok('LWP::UserAgent');
	use_ok( 'POE::Component::CSS::Minifier' );
}

diag( "Testing POE::Component::CSS::Minifier $POE::Component::CSS::Minifier::VERSION, Perl $], $^X" );
