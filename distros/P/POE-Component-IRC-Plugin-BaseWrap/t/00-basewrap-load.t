#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
    use_ok('Carp');
    use_ok('POE');
    use_ok('POE::Component::IRC::Plugin');
	use_ok( 'POE::Component::IRC::Plugin::BaseWrap' );
}

diag( "Testing POE::Component::IRC::Plugin::BaseWrap $POE::Component::IRC::Plugin::BaseWrap::VERSION, Perl $], $^X" );
