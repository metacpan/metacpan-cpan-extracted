#-*-perl-*-
use Test;
BEGIN { plan tests => 10 }

use ObjStore;
use lib './t';
use test;

&open_db;

my $sid;

begin 'update', sub {
    my $seg = $db->create_segment('tripwire');
    $sid = $seg->get_number;
    $db->root("tripwire", [1,2,3,'Oops, tripped!']);

    my $r = $db->find_root('empty') || $db->create_root('empty');
    ok(!defined $r->get_value) or warn $r->get_value;
    ok($r->get_name, 'empty');
    $r->set_value([0]);
    ok($r->get_value->[0], 0);
    $r->set_value([1]);
    ok($r->get_value->[0], 1);
    $r->destroy;
};
die if $@;

begin 'update', sub {
    $db->destroy_root('tripwire');

    my $rt = $db->find_root('_osperl_private');
    ok(! $rt);
    $rt = $db->_PRIVATE_ROOT();
    ok($rt);
    $rt = $db->find_root('_osperl_private');
    ok(! $rt);
};
die if $@;

begin 'update', sub {
    my $seg = $db->get_segment($sid);
    ok($seg->is_empty);
    $seg->destroy;
};
die if $@;

begin 'update', sub {
    my $ok=1;
    for ($db->get_all_roots()) {
	$ok=0 if $_->get_name eq '_osperl_private';
    }
    ok($ok);
};
die if $@;
