#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok('Carp');
    use_ok('POE');
    use_ok('POE::Component::IRC::Plugin');
	use_ok('POE::Component::IRC::Plugin::BasePoCoWrap');
}

diag( "Testing POE::Component::IRC::Plugin::BasePoCoWrap $POE::Component::IRC::Plugin::BasePoCoWrap::VERSION, Perl $], $^X" );
