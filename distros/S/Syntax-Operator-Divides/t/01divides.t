#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Operator::Divides;
BEGIN { plan skip_all => "No PL_infix_plugin" unless XS::Parse::Infix::HAVE_PL_INFIX_PLUGIN; }

ok(  15 %% 5 , '15 divides into 5');
ok(!(16 %% 5), '16 does not divide into 5');

done_testing;
