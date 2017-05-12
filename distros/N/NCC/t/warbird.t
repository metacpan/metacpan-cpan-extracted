#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/lib";
use DDP;

use NCC ();

use_ok('Khazara');
use_ok('Khazara::Test');

my $obj = Khazara::Test->new( roms => 2 );

isa_ok($obj,"Khazara::Test");
is($obj->roms,2,"Constructor value");

my $warpcore = NCC::engineering('Khazara::Test');

isa_ok($warpcore,'WarBird::WarpCore');

is_deeply($warpcore->calls,[qw(
  +Khazara
  +Khazara::Test
  -Khazara::Test
)],'Proper energize/enervate');

done_testing;
