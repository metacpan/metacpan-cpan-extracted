# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl APO_ID.t'

#########################

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 5;
}

#########################

use OBO::APO::APO_ID;
use strict;

my $my_id = OBO::APO::APO_ID->new();
$my_id->idspace('APO');
$my_id->subnamespace('P');
$my_id->localID('3000001');
ok($my_id->id_as_string() eq 'APO:P3000001');

my $my_id2 = OBO::APO::APO_ID->new();
$my_id2->idspace('APO');
$my_id2->subnamespace('P');
$my_id2->localID('3000001');

ok($my_id->equals($my_id2));
ok($my_id->next_id()->id_as_string() eq 'APO:P3000002');

ok($my_id->previous_id()->id_as_string() eq 'APO:P3000000');

ok(1);
