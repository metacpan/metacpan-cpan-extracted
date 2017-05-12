#!/usr/bin/perl

# Compile testing for Mirror::YAML

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use LWP::Online ':skip_all';
use Test::More tests => 1;
use URI          ();
use Mirror::CPAN ();

my $cpan = Mirror::CPAN->get(URI->new('http://cpan.org/'));
isa_ok( $cpan, 'Mirror::CPAN' );
