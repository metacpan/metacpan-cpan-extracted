#! perl

use Test::More;
use Test::Database;
use Data::Dumper;
use Nitesi::Query::DBI;

# statements produced by SQL::Abstract are not understood by DBI::SQL::Nano
use SQL::Statement;

my (@handles, $dbh, $dbd, $q, $ret, @set, %test_counts,
    %test_exclusion_map, %limited_handles, $tests, @keys);

@handles = Test::Database->handles();

$tests = 0;

%test_counts = ('multi_primary' => 4,
                'limit_offset' => 2,
                'serial' => 2,
                'other' => 6);

%test_exclusion_map = ('multi_primary' => {DBM => 1},
                       'limit_offset' => {CSV => 1, DBM => 1, SQLite2 => 1},
                       'serial' => {CSV => 1, DBM => 1, SQLite => 1, SQLite2 => 1},
    );

for my $testdb (@handles) {
    $tests += $test_counts{other};

    for my $test_type (keys %test_exclusion_map) {
        unless ($test_exclusion_map{$test_type}->{$testdb->dbd}) {
            $tests += $test_counts{$test_type};
        }
    }
}

if (@handles) {
    # determine number of tests
    plan tests => $tests;
}
else {
    plan skip_all => 'No test database handles available';
}

# run tests
for my $testdb (@handles) {
    diag 'Testing with DBI driver ' . $testdb->dbd();

    $dbh = $testdb->dbh();
    $dbd = $testdb->dbd();

    $q = Nitesi::Query::DBI->new(dbh => $dbh);

    isa_ok($q, 'Nitesi::Query::DBI');

    for my $t ('products', 'navigation', 'navigation_products') {
        if (grep {$_ =~ /^(.*?\.)?$t$/} $q->_tables) {
            $q->_drop_table($t);
        }
    }
    
    # create table
    $q->_create_table('products', ['sku varchar(32) primary key', 'name varchar(255)']);

    # insert
    $ret = $q->insert('products', {sku => '9780977920150', name => 'Modern Perl'});

    # distinguish between drivers support primary_key method properly
    @keys = $dbh->primary_key(undef, undef, 'products');
    if (@keys == 1) {
        ok(defined $ret && $ret eq '9780977920150', "return value of insert with $dbd driver");
    }
    else {
        ok($ret, "return value of insert with $dbd driver");
    }

    # select field
    $ret = $q->select_field(table => 'products', field => 'name', 
			    where => {sku => '9780977920150'});

    ok($ret eq 'Modern Perl', "select field with $dbd driver");

    # select all
    $ret = $q->select(table => 'products');
    ok(scalar(@$ret) == 1, "select all with $dbd driver");

    # delete record (positional)
    $q->delete('products', {sku => '9780977920150'});

    $ret = $q->select(table => 'products');
    ok(scalar(@$ret) == 0, "delete positional with $dbd driver");

    # delete record (named)
    $q->insert('products', {sku => '9780977920150', name => 'Modern Perl'});

    $q->delete(table => 'products', where => {sku => '9780977920150'});

    $ret = $q->select(table => 'products');
    ok(scalar(@$ret) == 0, "delete named with $dbd driver");

    unless ($test_exclusion_map{limit_offset}->{$dbd}) {
        # add records for limit tests
        $q->insert('products', {sku => 'ABC', name => 'Foo'});
        $q->insert('products', {sku => 'DEF', name => 'Bar'});
        $q->insert('products', {sku => 'GHI', name => 'Baz'});
        $q->insert('products', {sku => 'JKL', name => 'Zof'});
        $q->insert('products', {sku => 'MNO', name => 'Fab'});

        $ret = $q->select(table => 'products', fields => 'sku',
                          limit => 2);

        is_deeply($ret, [{sku => 'ABC'}, {sku => 'DEF'}],
                  "select limit 2 with $dbd driver")
            || diag "Output: ", Dumper($ret);

        $ret = $q->select(table => 'products', fields => 'sku',
                     limit => 2, offset => 1);

        is_deeply($ret, [{sku => 'DEF'}, {sku => 'GHI'}],
                  "select limit 2 offset 1 with $dbd driver")
            || diag "Output: ", Dumper($ret);
    }

    # drop table
    $q->_drop_table('products');

    unless ($test_exclusion_map{multi_primary}->{$dbd}) {
        # create table without primary key for testing distinct 
        $q->_create_table('navigation_products', ['sku varchar(32) NOT NULL', 
                                                  'navigation integer NOT NULL']);

        # insert records
        $q->insert('navigation_products', {sku => '9780977920150', navigation => 1});
        $q->insert('navigation_products', {sku => '9780977920150', navigation => 2});

        # normal select
        @set = $q->select_list_field(table => 'navigation_products', field => 'navigation');
        ok(scalar(@set) == 2, "select list field from navigation_products with $dbd driver");

        # distinct select (SQL::Abstract::More syntax)
        $ret = $q->select(table => 'navigation_products', fields => [-distinct => 'sku']);
        ok(scalar(@$ret) == 1, "select distinct from navigation_products with $dbd driver and original syntax");

        # distinct select (Nitesi::Query::DBI syntax)
        $ret = $q->select(table => 'navigation_products', fields => 'sku', distinct => 1);
        ok(scalar(@$ret) == 1, "select distinct from navigation_products with $dbd driver and our syntax");

        # distinct select list field
        @set = $q->select_list_field(table => 'navigation_products', field => 'sku', distinct => 1);
        ok(scalar(@set) == 1, "select distinct list field from navigation_products with $dbd driver")
            || diag scalar(@set) . " results instead on one";

        $q->_drop_table('navigation_products');
    }
    
    unless ($test_exclusion_map{serial}->{$dbd}) {
        # create table with serial field
        $q->_create_table('navigation', ['code serial NOT NULL primary key',
                                         q{uri varchar(255) NOT NULL DEFAULT ''}]);

        $ret = $q->insert('navigation', {uri => 'help'});
        ok($ret == 1, "first insert into table with serial with $dbd driver");
        
        $ret = $q->insert('navigation', {uri => 'about'});
        ok($ret == 2, "second insert into table with serial with $dbd driver")
            || diag "Return value for second insert: $ret.";
        
        $q->_drop_table('navigation');
    }
}

