#!/usr/bin/perl

##
## Tests for Petal::Utils :logic modifiers
##

use blib;
use strict;
#use warnings;

use Test::More qw( no_plan );

use Carp;
use t::LoadPetal;

use Petal::Utils qw( :logic );

my $hash = {
	first      => 0,
	second     => 1,
	first_name => "William",
	last_name  => "McKee",
	email      => 'william@knowmad.com',
};

my $template = Petal->new('logic.html');
my $out      = $template->process( $hash );

like($out, qr/first = 0/, 'first');
like($out, qr/second = 1/, 'second');

# Comparisons
like($out, qr/first or second = 1/, 'or');
like($out, qr/first and second = 0/, 'and');
like($out, qr/first eq second = 0/, 'equal');
like($out, qr/first_name like regex = 1/, 'like');

# If/then/else
like($out, qr/first then first else second = 1/, 'if');
like($out, qr/second then first else second = 0/, 'if');

