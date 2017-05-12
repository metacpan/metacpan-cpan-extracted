#!/usr/bin/env perl

use Test::More tests => 7;

BEGIN {
    use_ok('Carp');
    use_ok('POE');
    use_ok('POE::Wheel::Run');
    use_ok('POE::Filter::Reference');
    use_ok('POE::Filter::Line');
    use_ok('Archive::Any');
	use_ok( 'POE::Component::Archive::Any' );
}

diag( "Testing POE::Component::Archive::Any $POE::Component::Archive::Any::VERSION, Perl $], $^X" );
