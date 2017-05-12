# -*-perl-*-

use strict;
use Test; plan test => 8;
use ObjStore;
use ObjStore::REP::Ring;

my $o = ObjStore::REP::Ring::Index::new('ObjStore::Index', 'transient');
ok @$o, 0;
$o->[0] = [0];
ok @$o, 1;
ok $o->[0]->[0], 0;

$o->[400] = [400];
ok @$o, 401;

$o->[200] = [200];

for (0..400) {
    my $at = $o->[$_];
    next if !$at;
    ok $at->[0], $_;
}
@$o = ();
ok @$o, 0;
