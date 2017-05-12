#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use Test::NoWarnings;

use_ok( 'Padre::Plugin::FormBuilder'         );
use_ok( 'Padre::Plugin::FormBuilder::Perl'   );
use_ok( 'Padre::Plugin::FormBuilder::FBP'    );
use_ok( 'Padre::Plugin::FormBuilder::Dialog' );
