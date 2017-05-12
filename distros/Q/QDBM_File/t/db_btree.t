#!perl -w

# QDBM_File::BTree test script based on DB_File - db_btree.t

use strict;
use Test::More tests => 109;
use Fcntl;
use File::Path;
use File::Spec;

BEGIN {
    use_ok('QDBM_File');
}

my $class = 'QDBM_File::BTree';
my $tempdir  = "t/db_btree_temp";
mkpath($tempdir);
my $tempfile = File::Spec->catfile( $tempdir, "db_btree_test" );

END {
    rmtree($tempdir);
}

my $compare = sub { $_[0] cmp $_[1] };

my %tie;
my $db = tie %tie, $class, $tempfile, O_RDWR|O_CREAT, 0640, $compare;

isa_ok($db, $class);

sub count_ok {
    my $count = shift;
    my $i = 0;
    my ($key, $value);
    while ( ($key, $value) = each %tie  ) { $i++; }
    is($i, $count);
}

count_ok(0);

$tie{'abc'} = 'ABC';

ok( exists $tie{'abc'} );
is( $tie{'abc'}, 'ABC' );
ok( !exists $tie{'def'} );
ok( !defined $tie{'def'} );

$tie{'abc'} = "Null \0 Value";
is( $tie{'abc'}, "Null \0 Value" );

delete $tie{'abc'};
ok( !exists $tie{'abc'} );

$tie{"null\0key"} = "Null Key";
is( $tie{"null\0key"}, "Null Key" );
delete $tie{"null\0key"};
ok( !exists $tie{"null\0key"} );

count_ok(0);

$tie{'a'} = "A";
$tie{'b'} = "B";

undef $db;
untie %tie;

$db = tie %tie, $class, $tempfile, O_RDWR, 0640, $compare;
ok($db);

is( $tie{'a'}, "A" );
is( $tie{'b'}, "B" );

$tie{'c'} = "C";
$tie{'d'} = "D";
$tie{'e'} = "E";
$tie{'f'} = "F";

{
    my @keys   = keys   %tie;
    my @values = values %tie;
    ok(@keys == 6 and @values == 6);
}

{
    my $i = 0;
    my ($key, $value);
    while ( ($key, $value) = each %tie ) {
        if ($key eq lc $value) { $i++; }
    }
    ok($i == 6);
}

$tie{'empty value'} = '';
ok( $tie{'empty value'} eq '' );

$tie{''} = 'empty key';
ok( $tie{''} eq 'empty key' );

count_ok(8);
is( scalar(%tie), 8 );

$tie{'cattest'} = "CAT";
$db->store_cat('cattest', "TEST");
is( $tie{'cattest'}, "CATTEST" );

my $stat = eval { $db->store_keep('keeptest', "KEEP"); };
ok($stat);
is( $tie{'keeptest'}, "KEEP" );
$stat = eval { $db->store_keep('keeptest', "KEEP2"); };
ok(!$stat);
is( $tie{'keeptest'}, "KEEP" );

ok(QDBM_File::BTree->get_error);
ok(!$db->is_fatal_error);
ok($db->get_name =~ /db_btree_test/);
ok($db->get_mtime);
ok( 0 < $db->get_record_size("cattest") );
ok( 0 < $db->count_match_records("cattest") );
#ok(eval { $db->count_buckets; });
#ok(eval { $db->count_used_buckets; });
ok(eval { $db->count_records; });
ok($db->is_writable);
ok(0 < eval { $db->get_size; });
ok($db->init_iterator);
ok(eval { $db->sync; });
ok(eval { $db->optimize; });

my $temp_export = File::Spec->catfile( $tempdir, "db_btree_export_test" );
ok(eval { $db->export_db($temp_export); });

undef $db;
untie %tie;

SKIP: {
    skip q(I don't know how create crashed file), 1;
    ok( $class->repair($tempfile, $compare) );
}

$db = tie %tie, $class, $tempfile, O_RDWR|O_CREAT|O_TRUNC, 0640, $compare;
count_ok(0);
ok(eval { $db->import_db($temp_export); });

is( $tie{'a'}, "A" );
is( $tie{'b'}, "B" );
is( $tie{'c'}, "C" );
is( $tie{'d'}, "D" );
is( $tie{'e'}, "E" );
is( $tie{'f'}, "F" );
ok( $tie{'empty value'} eq '' );
ok( $tie{''} eq 'empty key' );

my ($fetch_key, $store_key, $fetch_value, $store_value) = ("") x 4;

$db->filter_fetch_key(sub { $fetch_key = $_ }) ;
$db->filter_store_key(sub { $store_key = $_ }) ;
$db->filter_fetch_value(sub { $fetch_value = $_}) ;
$db->filter_store_value(sub { $store_value = $_ }) ;

$tie{'filter_key'} = 'filter_value';
is( $store_key, 'filter_key' );
is( $store_value, 'filter_value' );

is( $tie{'filter_key'}, 'filter_value' );
is( $fetch_value, 'filter_value' );

my $next_key = $db->FIRSTKEY;
is( $fetch_key, $next_key );

undef $db;
untie %tie;

$db = tie %tie, $class, $tempfile, O_RDWR|O_CREAT|O_TRUNC, 0640, $compare;

ok( $db->store_list("store_list", "LIST_A", "LIST_B", "LIST_C") );

my @list = $db->fetch_list("store_list");
ok(@list == 3);
is( $list[0], "LIST_A" );
is( $list[1], "LIST_B" );
is( $list[2], "LIST_C" );

ok( $db->move_backword("store_list") );
is( $db->get_current_value(), "LIST_C");

ok( $db->store_after("LIST_E") );
ok( $db->store_before("LIST_D") );

ok( $db->move_forward("store_list") );
is( $db->get_current_value(), "LIST_A");

my @list2 = $db->fetch_list("store_list");
ok(@list2 == 5);

is( $list2[0], "LIST_A" );
is( $list2[1], "LIST_B" );
is( $list2[2], "LIST_C" );
is( $list2[3], "LIST_D" );
is( $list2[4], "LIST_E" );

ok( $db->delete_list("store_list") );

$tie{'b'} = "B";
$tie{'a'} = "A";
$tie{'e'} = "E";
$tie{'c'} = "C";
$tie{'f'} = "F";
$tie{'d'} = "D";

my @key_order = keys %tie;
is( $key_order[0], "a" );
is( $key_order[1], "b" );
is( $key_order[2], "c" );
is( $key_order[3], "d" );
is( $key_order[4], "e" );
is( $key_order[5], "f" );

ok( $db->move_last() );
ok( $db->move_first() );

is( $db->get_current_key(), "a" );
is( $db->get_current_value(), "A" );

ok( $db->move_next() );
is( $db->get_current_key(), "b" );
is( $db->get_current_value(), "B" );

ok( $db->move_prev() );
is( $db->get_current_key(), "a" );
is( $db->get_current_value(), "A" );

undef $db;
untie %tie;

$db = tie %tie, $class, $tempfile, O_RDWR|O_CREAT|O_TRUNC, 0640, $compare;

ok( $db->begin_transaction() );

$tie{"a"} = "A";
$tie{"b"} = "B";
$tie{"c"} = "C";
$tie{"d"} = "D";

ok( $db->commit() );

ok( $db->begin_transaction() );

$tie{"e"} = "E";
$tie{"f"} = "F";

ok( $db->rollback() );

undef $db;
untie %tie;

$db = tie %tie, $class, $tempfile, O_RDWR, 0640, $compare;

is( $tie{"a"}, "A" );
is( $tie{"b"}, "B" );
is( $tie{"c"}, "C" );
is( $tie{"d"}, "D" );

ok( !exists $tie{"e"} );
ok( !exists $tie{"f"} );

undef $db;
untie %tie;

my $temp_default = File::Spec->catfile( $tempdir, "db_btree_default_test" );

$db = tie %tie, $class, $temp_default;

$tie{'b'} = "B";
$tie{'a'} = "A";
$tie{'e'} = "E";
$tie{'c'} = "C";
$tie{'f'} = "F";
$tie{'d'} = "D";

my @key_order2 = keys %tie;

is( $key_order2[0], "a" );
is( $key_order2[1], "b" );
is( $key_order2[2], "c" );
is( $key_order2[3], "d" );
is( $key_order2[4], "e" );
is( $key_order2[5], "f" );

ok( scalar(%tie) );
%tie = ();
ok( !scalar(%tie) );
count_ok(0);

undef $db;
untie %tie;

my $db2 = $class->new($tempfile, O_RDWR|O_CREAT, 0640);
isa_ok($db2, $class);
undef $db2;
