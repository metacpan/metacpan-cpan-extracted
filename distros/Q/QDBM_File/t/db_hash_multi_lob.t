#!perl -w

# QDBM_File::Multiple large object test script based on DB_File - db_hash.t

use strict;
use Test::More tests => 24;
use Fcntl;
use File::Path;
use File::Spec;

BEGIN {
    use_ok('QDBM_File');
}

my $class = "QDBM_File::Multiple";
my $tempdir = "t/db_hash_multi_lob_temp";
mkpath($tempdir);
my $tempfile = File::Spec->catfile($tempdir, "db_hash_multi_lob_test");

my %tie;
my $db = tie %tie, $class, $tempfile, O_RDWR|O_CREAT, 0640;

END {
    rmtree($tempdir);
}

isa_ok($db, $class);

$db->store_lob('abc', 'ABC');

ok( $db->exists_lob('abc') );
is( $db->fetch_lob('abc'), 'ABC' );
ok( !$db->exists_lob('def') );
ok( !defined $db->fetch_lob('def') );

$db->store_lob('abc', "Null \0 Value");
is( $db->fetch_lob('abc'), "Null \0 Value" );

$db->delete_lob('abc');
ok( !$db->exists_lob('abc') );

$db->store_lob("null\0key", "Null Key");
is( $db->fetch_lob("null\0key"), "Null Key" );
$db->delete_lob("null\0key");
ok( !$db->exists_lob("null\0key") );

$db->store_lob("a", "A");
$db->store_lob("b", "B");

undef $db;
untie %tie;

$db = tie %tie, $class, $tempfile, O_RDWR, 0640;
ok($db);

is( $db->fetch_lob("a"), "A" );
is( $db->fetch_lob("b"), "B" );

$db->store_lob("c", "C");
$db->store_lob("d", "D");
$db->store_lob("e", "E");
$db->store_lob("f", "F");

is( $db->count_lob_records, 6 );

$db->store_lob("empty value", "");
ok( $db->fetch_lob("empty value") eq "" );

SKIP: {
    my $stat1 = eval { $db->store_lob("", "empty key") };

    if (!$stat1) {
        skip("LOB: can not use empty key", 1);
    }

    ok($stat1);
}

$db->store_lob("cattest", "CAT");
$db->store_cat_lob("cattest", "TEST");
is( $db->fetch_lob("cattest"), "CATTEST" );

my $stat2 = eval { $db->store_keep_lob("keeptest", "KEEP"); };
ok($stat2);
is( $db->fetch_lob("keeptest"), "KEEP" );
$stat2 = eval { $db->store_keep_lob("keeptest", "KEEP2"); };
ok(!$stat2);
is( $db->fetch_lob("keeptest"), "KEEP" );

ok(0 < eval { $db->get_size; });
ok(eval { $db->sync; });
ok(eval { $db->optimize; });

undef $db;
untie %tie;
