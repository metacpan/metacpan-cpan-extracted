#!/usr/bin/perl -w

#
# Test the isa() relations
#

use strict;
use Test;

use lib 't', '.', 't/testmods', 'testmods';
use C::D::E;

BEGIN { plan tests => 23 }

my $obj = C::D->new;
ok($obj);

ok($obj->isa('C'));
ok(not $obj->isa('C::D::E'));
ok($obj->isa('A::B'));
ok($obj->isa('A'));

ok(not $obj->isa('GarbleBlaster'));

ok(C::D::E->isa('C::D::E'));
ok(C::D::E->isa('C::D'));
ok(C::D::E->isa('C'));
ok(C::D->isa('C::D'));
ok(C::D->isa('C'));
ok(C->isa('C'));

ok(not C::D->isa('GarbleBlaster'));

ok(C::D::E->isa('A::B'));
ok(C::D::E->isa('A'));
ok(C::D->isa('A::B'));
ok(C::D->isa('A'));
ok(not C->isa('A::B'));
ok(not C->isa('A'));

ok(not A::B->isa('C::D'));
ok(not A::B->isa('C'));
ok(not A->isa('C::D'));
ok(not A->isa('C'));
