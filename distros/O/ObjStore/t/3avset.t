# set -*-perl-*-
use Test 1.00;
BEGIN { plan tests => 13; }

use strict;
use ObjStore ':ADV';
require ObjStore::AV::Set;
use lib './t';
use test;

&open_db;
begin 'update', sub {
    my $j = $db->root('John');
    die "no db" if !$j;

    my $s = new ObjStore::AV::Set($j, 12);
    ok($s->FETCHSIZE, 0);

#    ObjStore::debug qw(PANIC);
    $s->add({box => 1});
    $s->add({box => 2});
    $s->add({box => 2});
    ok($s->FETCHSIZE, 3);

    my @b;
    $s->map(sub { push(@b, shift) });
    ok(scalar(@b), 3);

    ok($s->exists($b[0]),1);
    ok($s->exists($b[1]),1);
    ok($s->exists($b[2]),1);
    ok(!$s->exists({}),1);

    $s->add($b[1]);
    ok($s->FETCHSIZE, 3);

    $s->remove($b[1]->HOLD);
    ok($s->FETCHSIZE, 2);
    ok($s->exists($b[0]), 1);
    ok(!$s->exists($b[1]), 1);
    ok($s->exists($b[2]), 1);
};
die if $@;
