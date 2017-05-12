#!/usr/bin/perl

##
## Tests for Petal::Utils::Limitr module
##

use blib;
use strict;

use Test::More qw(no_plan);
use Carp;

use t::LoadPetal;
use Petal::Utils qw( :list );

my $template = Petal->new('22__limitr.html');
my $out      = $template->process( {
    items => [ 'item1', 'item2', 'item3' ],
  } );

like($out, qr/nolimit: item1item2item3/, 'no limit');
like($out, qr/limitr1: item\d/, 'limit 1');
like($out, qr/limitr2: item\ditem\d/, 'limit 2');

