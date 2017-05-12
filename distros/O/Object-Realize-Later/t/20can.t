#!/usr/bin/perl -w

#
# Test the can() relations
#

use strict;
use Test;

use lib 't', '.', 't/testmods', 'testmods';
use C::D::E;

BEGIN { plan tests => 26 }

my $obj = C::D->new;
ok($obj);

ok(defined $obj->can('c'));
ok(not $obj->can('c_d_e'));
ok(defined $obj->can('a_b'));
ok(defined $obj->can('a'));

ok(defined C::D::E->can('c_d_e'));
ok(defined C::D::E->can('c_d'));
ok(defined C::D::E->can('c'));
ok(defined C::D->can('c_d'));
ok(defined C::D->can('c'));
ok(defined C->can('c'));

ok(defined C::D::E->can('a_b'));
ok(defined C::D::E->can('a'));
ok(defined C::D->can('a_b'));
ok(defined C::D->can('a'));
ok(not defined C->can('a_b'));
ok(not defined C->can('a'));

ok(not defined A::B->can('c_d'));
ok(not defined A::B->can('c'));
ok(not defined A->can('c_d'));
ok(not defined A->can('c'));

ok(defined C::D->can('willRealize'));
ok(defined C::D::E->can('willRealize'));
ok(!defined C->can('willRealize'));
ok(C::D->willRealize eq 'A::B');
ok(C::D::E->willRealize eq 'A::B');
