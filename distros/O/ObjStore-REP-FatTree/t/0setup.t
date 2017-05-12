#!./perl -w

use Test; plan tests => 1;
use ObjStore;
use ObjStore::REP::FatTree;

use vars qw($db);
require "t/db.pm";

begin 'update', sub {
    my $j = $db->root('hv', sub { {} });
};
die if $@;

ok 1;
