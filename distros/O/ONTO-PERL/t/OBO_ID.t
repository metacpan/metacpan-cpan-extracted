# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl OBO_ID.t'

#########################

BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 8;
}

#########################

use OBO::XO::OBO_ID;
use strict;

my $my_id = OBO::XO::OBO_ID->new();
$my_id->idspace("XO");
$my_id->localID("3000001");
ok($my_id->id_as_string() eq "XO:3000001");

my $my_id2 = OBO::XO::OBO_ID->new();
$my_id2->idspace("XO");
$my_id2->localID("3000001");

ok($my_id->equals($my_id2));
ok($my_id->next_id()->id_as_string() eq "XO:3000002");
ok($my_id->previous_id()->id_as_string() eq "XO:3000000");

my $my_id3 = OBO::XO::OBO_ID->new();
$my_id3->idspace("TO");
$my_id3->localID("0000479");
ok($my_id3->next_id()->id_as_string() eq "TO:0000480");
ok($my_id3->previous_id()->id_as_string() eq "TO:0000478");

my $my_id4 = OBO::XO::OBO_ID->new();
$my_id4->id_as_string("TO:0000479");
ok($my_id4->equals($my_id3));

ok(1);
