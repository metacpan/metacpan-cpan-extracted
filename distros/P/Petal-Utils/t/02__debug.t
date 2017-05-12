#!/usr/bin/perl

##
## Tests for Petal::Utils :debug modifiers
##

use blib;
use strict;
#use warnings;

use Test::More qw( no_plan );

use Carp;
use t::LoadPetal;

use Petal::Utils qw( :debug );

my $hash = {
	debug => { name => 'test', array => [ 1..3 ] },
};
my $template = Petal->new('debug.html');
my $out      = $template->process( $hash );

# Dump
like($out, qr/dump: \$VAR1/, 'dump');
