#!/usr/bin/perl

##
## Tests for Petal::Utils :list modifiers
##

use blib;
use strict;
#use warnings;

use Test::More qw( no_plan );

use Carp;
use t::LoadPetal;

use Petal::Utils qw( :list );

my $hash = {
	array_ref => [ 1..3 ],
};
my $template = Petal->new('list.html');
my $out      = $template->process( $hash );

# Sort
like($out, qr/sort:.+?1.+2.+3/, 'sort');

