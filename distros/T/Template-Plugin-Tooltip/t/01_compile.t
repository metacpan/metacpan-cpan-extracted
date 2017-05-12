#!/usr/bin/perl

# Load testing for Template::Plugin::Tooltip

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;

# Does everything load?
ok( $] >= 5.005, 'Your perl is new enough' );
use_ok( 'Template::Plugin::Tooltip' );

# Is Scalar::Util loaded and do we have the blessed function
ok( $Scalar::Util::VERSION, 'Scalar::Util loaded ok' );
ok( defined &Scalar::Util::blessed, 'Scalar::Util has the "blessed" function' );
