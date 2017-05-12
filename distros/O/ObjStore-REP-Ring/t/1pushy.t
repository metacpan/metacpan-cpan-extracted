# -*-perl-*-

use strict;
use Test; plan test => 14;
use ObjStore;
use ObjStore::REP::Ring;

my $o = ObjStore::REP::Ring::Index::new('ObjStore::Index', 'transient');

push @$o, [1];
ok @$o, 1;
ok((shift @$o)->[0], 1);
ok @$o, 0;

unshift @$o, [1];
ok @$o, 1;
ok((pop @$o)->[0], 1);
ok @$o, 0;

for (1..400) { push @$o, [$_]; }
my $c=0;
ok $o->[100][0], 101;
while (@$o) { shift @$o; ++$c; }
ok $c, 400;

for (1..400) { unshift @$o, [$_]; }
$c=0;
ok $o->[100][0], 300;
while (@$o) { pop @$o; ++$c; }
ok $c, 400;

$o = ObjStore::REP::Ring::Index::new('ObjStore::Index', 'transient');

my @chunk;
for (1..200) { push @chunk, [$_]; }
push @$o, @chunk;
push @$o, @chunk;
ok @$o, 400;
ok $o->[150][0], 151;

@$o = ();
unshift @$o, @chunk;
unshift @$o, @chunk;
ok @$o, 400;
ok $o->[150][0], 7;
