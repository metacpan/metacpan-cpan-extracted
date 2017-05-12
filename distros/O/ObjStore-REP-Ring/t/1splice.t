# -*-perl-*-

use strict;
use Test; plan test => 0;
use ObjStore;
use ObjStore::REP::Ring;

my $o = ObjStore::REP::Ring::Index::new('ObjStore::Index', 'transient');

# I hate testing splice :-(
