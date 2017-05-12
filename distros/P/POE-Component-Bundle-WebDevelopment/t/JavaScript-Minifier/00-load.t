#!/usr/bin/env perl

use Test::More tests => 5;

BEGIN {
    use_ok('POE');
    use_ok('POE::Component::NonBlockingWrapper::Base');
    use_ok('LWP::UserAgent');
    use_ok('JavaScript::Minifier');
	use_ok( 'POE::Component::JavaScript::Minifier' );
}

diag( "Testing POE::Component::JavaScript::Minifier $POE::Component::JavaScript::Minifier::VERSION, Perl $], $^X" );
