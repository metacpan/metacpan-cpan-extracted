#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
    use_ok('Carp');
    use_ok('POE::Component::IRC::Plugin::BaseWrap');
    use_ok('Unicode::UCD');
    use_ok('Encode');
	use_ok('POE::Component::IRC::Plugin::Unicode::UCD');
}

diag( "Testing POE::Component::IRC::Plugin::Unicode::UCD $POE::Component::IRC::Plugin::Unicode::UCD::VERSION, Perl $], $^X" );
