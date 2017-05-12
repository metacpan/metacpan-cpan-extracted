# indexed -*-perl-*-
use Test 1.03; plan tests=>58;

use ObjStore ':ADV';
use ObjStore::REP::FatTree;
use ObjStore::Test qw(testofy_index);

use vars qw($db);
require "t/db.pm";

begin 'update', sub {
    my $j = $db->root('hv');
    my $rep = 'ObjStore::REP::FatTree::Index';
    my $mk = sub { &{$rep.'::new'}('ObjStore::Index', $db->segment_of) };
    $j->{$rep} = $mk->();
    testofy_index(29, $mk);
    $rep = 'ObjStore::REP::FatTree::KCIndex';
    $mk = sub { &{$rep.'::new'}('ObjStore::Index', $db->segment_of) };
    $j->{$rep} = $mk->();
    testofy_index(29, $mk);
};
die if $@;
