# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Set.t'

#########################

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 20;
}

#########################

use OBO::Util::Set;
use strict;

my $my_set = OBO::Util::Set->new();
ok(1);

ok(!$my_set->contains('APO:P0000001'));
$my_set->add('APO:P0000001');
ok($my_set->contains('APO:P0000001'));

$my_set->add_all('APO:P0000002', 'APO:P0000003', 'APO:P0000004');
ok($my_set->contains('APO:P0000002') && $my_set->contains('APO:P0000003') && $my_set->contains('APO:P0000004'));

my $c = 1;
foreach (sort {$a cmp $b} $my_set->get_set()) {
	ok('APO:P000000'.$c++ eq $_);
}


my $my_set2 = OBO::Util::Set->new();
ok(1);

$my_set2->add_all('APO:P0000001', 'APO:P0000002', 'APO:P0000003', 'APO:P0000004');
ok($my_set2->contains('APO:P0000002') && $my_set->contains('APO:P0000003') && $my_set->contains('APO:P0000004'));
ok($my_set->equals($my_set2));
ok($my_set2->size() == 4);

$my_set2->remove('APO:P0000003');
ok($my_set2->contains('APO:P0000001') && $my_set->contains('APO:P0000002') && $my_set->contains('APO:P0000004'));
ok($my_set2->size() == 3);

$my_set2->remove('APO:P0000005');
ok($my_set2->contains('APO:P0000001') && $my_set->contains('APO:P0000002') && $my_set->contains('APO:P0000004'));
ok($my_set2->size() == 3);

$my_set2->clear();
ok(!$my_set2->contains('APO:P0000001') || !$my_set->contains('APO:P0000002') || !$my_set->contains('APO:P0000004'));
ok($my_set2->size() == 0);
ok($my_set2->is_empty());
ok(1);
