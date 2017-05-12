#!/usr/bin/env perl

use Test::More tests => 5;

BEGIN {
    use_ok('LWP::UserAgent');
    use_ok('POE');
    use_ok('POE::Component::NonBlockingWrapper::Base');
    use_ok('Syntax::Highlight::CSS');
	use_ok( 'POE::Component::Syntax::Highlight::CSS' );
}

diag( "Testing POE::Component::Syntax::Highlight::CSS $POE::Component::Syntax::Highlight::CSS::VERSION, Perl $], $^X" );
