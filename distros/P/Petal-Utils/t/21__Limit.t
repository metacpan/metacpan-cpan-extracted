#!/usr/bin/perl

##
## Tests for Petal::Utils::Limit module
##

use blib;
use strict;

use Test::More qw(no_plan);
use Carp;

use t::LoadPetal;
use Petal::Utils qw( :list );

my $template = Petal->new('21__limit.html');
my $out      = $template->process( {
    items => [ 'item1', 'item2', 'item3' ],
  } );

like($out, qr/nolimit: item1item2item3/, 'no limit');
like($out, qr/limit1: item1/, 'limit 1');
like($out, qr/limit2: item1item2/, 'limit 2');

