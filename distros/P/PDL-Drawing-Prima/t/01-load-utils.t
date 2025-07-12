#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;
use Prima::noX11;
use Prima;

BEGIN {
    use_ok( 'PDL::Drawing::Prima::Utils' )
		or BAIL_OUT('Unable to load PDL::Drawing::Prima::Utils!');
}
use PDL::Drawing::Prima;

diag( "Testing PDL::Drawing::Prima::Utils $PDL::Drawing::Prima::Utils::VERSION, Perl $], $^X" );
