# -*-perl-*-

use Test; BEGIN { plan test => 3 }
use ObjStore;
use ObjStore::REP::Ring;

ok 1;
my $o = ObjStore::REP::Ring::Index::new('ObjStore::Index', 'transient');
ok $o->os_class, 'ObjStore::Index';
ok $o->rep_class, 'ObjStore::REP::Ring::Index';
