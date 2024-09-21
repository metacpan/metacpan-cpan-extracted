#!/usr/bin/perl

use v5.18;
use warnings;

use Test2::V0;

use Object::Pad 0.800;

use lib "t/lib";
BEGIN { require "91rt141483Role.pm" }

class C { apply R; }

is( C->new->name, "Gantenbein", 'Value preserved from role-scoped lexical' );

done_testing;
