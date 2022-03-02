#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Object::Pad;

use lib "t/lib";
BEGIN { require "91rt141483Role.pm" }

class C :does(R) { }

is( C->new->name, "Gantenbein", 'Value preserved from role-scoped lexical' );

done_testing;
