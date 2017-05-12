#!/usr/bin/perl -w
# -*- perl -*-
# By Slavan Rezic <slaven@rezic.de>   2003-07-29

use strict;
use Test;

use lib "t/testmods";
use I;

BEGIN { plan tests => 3 }

my $i_obj = I->new;
ok(ref $i_obj, "I");
ok($i_obj->a_method, 42);
ok(ref $i_obj, "Another::Class");
