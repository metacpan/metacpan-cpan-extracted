#!./perl -w

use Test; plan tests => 31;
use ObjStore;
use ObjStore::Test qw(testofy_av);
use ObjStore::REP::FatTree;

use vars qw($db);
require "t/db.pm";

$SIG{__WARN__} = sub {
    my $m = $_[0];
    if ($m !~ m/ line \s+ \d+ (\.)? $/x) {
	warn $m;
    } else {
	print "# [WARNING] $_[0]"; #hide from Test::Harness
    }
};

begin 'update', sub {
    my $j = $db->root('hv');
    my $rep = 'ObjStore::REP::FatTree::AV';
    my $mk = sub { &{$rep.'::new'}('ObjStore::AV', $db->segment_of, 7)};
    $j->{$rep} = $mk->();
    testofy_av(31, $mk);
};
die if $@;
