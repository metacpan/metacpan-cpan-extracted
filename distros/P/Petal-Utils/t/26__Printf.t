#!/usr/bin/perl

##
## Tests for Petal::Utils::Printf module
##

use blib;
use strict;

use Test::More qw(no_plan);
use Carp;
use Data::Dumper;

use t::LoadPetal;
use Petal::Utils qw( :logic :text );

my $children = [ qw(Elroy Judi) ];

my $template = Petal->new('26__printf.html');
my $out      = $template->process( {
    dad => 'George',
    mom => 'Jane',
    dog => 'Astro',
    children => $children,
    children_count => scalar @$children,
    bank_balance => '201.5',
  } );

like($out, qr/printf1: Astro\n/, 'printf1');
like($out, qr/printf2: 02\n/, 'printf2');
like($out, qr/printf3: 201.50\n/, 'printf3');
like($out, qr/printf4: \$201.50\n/, 'printf4');
like($out, qr/printf5: Balance = \$201.50\n/, 'printf5');
like($out, qr/printf6: George and Jane\n/, 'printf6');


