#!perl -T

use Test::More tests => 9;

use RPM::Search;

my $db = RPM::Search->new(
    cache_base => "t/test"
);

isa_ok($db, "RPM::Search");
like($db->yum_primary_db, qr/0A6358CF-0BEC-46A8-B3D5-8D5CE49C28F7primary.sqlite/, "Found right DB");
like($db->dbh, qr/dbi/i, "DB handle open");

is((scalar $db->search()), 4, "Got 4 results total");
is((join " ", $db->search(qr/^foo/)), 'foobar foobaz', "Found ^foo");
is(($db->search('quux'))[0], 'quux', "Found quux");
is((join " ", $db->search("f*")), "foobar foobaz", "Found f*");
is((join " ", $db->search("%ba_")), "foobar foobaz bazbar", "Found %ba_");
is((scalar $db->search("kweepa")), 0, "Got 0 results for kweepa");
