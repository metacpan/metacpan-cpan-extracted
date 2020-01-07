use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Test::Warn;

plan skip_all => q{TEST_MYSQL=mysql://root@/test or TEST_POSTGRESQL=postgresql://root@/test}
    unless $ENV{TEST_MYSQL} or $ENV{TEST_POSTGRESQL};

my @mojo_dbs_config = (
    $ENV{TEST_MYSQL} ? do {
        require Mojo::mysql;

        {
            creator => sub { Mojo::mysql->new($ENV{TEST_MYSQL}) },
            drop_table_sql => 'DROP TABLE IF EXISTS people',
            create_table_sql => q{
                CREATE TABLE `people` (
                    `id` INT(11) NOT NULL AUTO_INCREMENT,
                    `name` VARCHAR(255) NOT NULL,
                    `age` INT(11) NOT NULL,
                    `favorite_food` VARCHAR(255) NOT NULL,
                    PRIMARY KEY (`id`)
                )
                AUTO_INCREMENT=1
            },
        }
    } : (),
    $ENV{TEST_POSTGRESQL} ? do {
        require Mojo::Pg;

        {
            creator => sub { Mojo::Pg->new($ENV{TEST_POSTGRESQL}) },
            drop_table_sql => 'DROP TABLE IF EXISTS people',
            create_table_sql => q{
                CREATE TABLE people (
                    id serial NOT NULL primary key,
                    name VARCHAR(255) NOT NULL,
                    age integer NOT NULL,
                    favorite_food VARCHAR(255) NOT NULL
                )
            },
        }
    } : (),
);

for my $mojo_db_config (@mojo_dbs_config) {
    for my $role (qw(Mojo::DB::Results::Role::MoreMethods +MoreMethods)) {
        my $mojo_db = $mojo_db_config->{creator}->();
        note "Testing @{[ ref $mojo_db ]} with role $role";

        my $db = $mojo_db->db;
        test_list_context($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role);
        test_scalar_context($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role);
    }
}

done_testing;

sub test_list_context {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;
    ok $db->ping, 'connected';

    $db->query($drop_table_sql);
    $db->query($create_table_sql);
    $db->insert(people => {name => 'Bob', age => 23, favorite_food => 'Pizza'});

    note 'Test calling one in void context warns';
    my $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                     ->with_roles($role)
                     ;

    is $results->rows, 1, '1 row returned';
    warning_like
        { $results->one }
        qr/get or get variant called without using return value/,
        'one called in void context warns';

    test_list_context_empty_results($results);

    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    is $results->rows, 1, '1 row returned';
    warning_like
        { $results->one(0, 1, 2) }
        qr/get or get variant called without using return value/,
        'one called with multiple indexes in void context warns';

    test_list_context_empty_results($results);

    note 'Test list context with no index';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    is $results->rows, 1, '1 row returned';
    my ($name, $age, $favorite_food) = $results->one;
    is $name, 'Bob', 'expected name returned in list context';
    is $age, 23, 'expected age returned in list context';
    is $favorite_food, 'Pizza', 'expected favorite food returned in list context';

    test_list_context_empty_results($results);

    note 'Test list context with one index';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    is $results->rows, 1, '1 row returned';
    my @values = $results->one(1);
    is scalar @values, 1, 'one value should be returned';
    is $values[0], 23, 'expected age returned';

    test_list_context_empty_results($results);

    note 'Test list context with multiple indexes';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    is $results->rows, 1, '1 row returned';
    ($favorite_food, $name) = $results->one(2, 0);
    is $favorite_food, 'Pizza', 'expected favorite food returned in list context using indexes';
    is $name, 'Bob', 'expected name returned in list context using indexes';

    test_list_context_empty_results($results);

    note 'Test negative indexes';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    is $results->rows, 1, '1 row returned';
    ($favorite_food, $name) = $results->one(-1, -3);
    is $favorite_food, 'Pizza', 'expected favorite food returned in list context using negative indexes';
    is $name, 'Bob', 'expected name returned in list context using negative indexes';

    test_list_context_empty_results($results);

    note 'Test valid indexes live';
    for my $index (-3..2) {
        $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                      ->with_roles($role)
                      ;

        is $results->rows, 1, '1 row returned';
        lives_ok { @values = $results->one($index) } "valid index '$index' lives";
    }

    note 'Test invalid indexes throw';
    for my $index (-5, -4, 3, 4) {
        $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                      ->with_roles($role)
                      ;

        is $results->rows, 1, '1 row returned';
        throws_ok
            { @values = $results->one($index) }
            qr/index out of valid range -3 to 2/,
            "invalid index '$index' throws";
    }

    note 'Test getting multiple rows';
    $db->insert(people => {name => 'Alice', age => 27, favorite_food => 'Hamburgers'});

    $results = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                  ->with_roles($role)
                  ;

    is $results->rows, 2, '2 rows returned';
    throws_ok
        { ($name, $age, $favorite_food) = $results->one }
        qr/multiple rows returned/,
        'test multiple rows throws';
}

sub test_list_context_empty_results {
    my ($results) = @_;

    throws_ok
        { my @values = $results->one }
        qr/no results/,
        'no results throws in list context';
}

sub test_scalar_context {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;
    ok $db->ping, 'connected';

    $db->query($drop_table_sql);
    $db->query($create_table_sql);
    $db->insert(people => {name => 'Bob', age => 23, favorite_food => 'Pizza'});

    note 'Test calling one in void context warns';
    my $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                     ->with_roles($role)
                     ;

    is $results->rows, 1, '1 row returned';
    warning_like
        { $results->one }
        qr/get or get variant called without using return value/,
        'one called in void context warns';

    test_scalar_context_empty_results($results);

    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    is $results->rows, 1, '1 row returned';
    warning_like
        { $results->one(1) }
        qr/get or get variant called without using return value/,
        'one called with index in void context warns';

    test_scalar_context_empty_results($results);

    note 'Test scalar context with no index';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    is $results->rows, 1, '1 row returned';
    my $name = $results->one;
    is $name, 'Bob', 'expected name returned in scalar context';

    test_scalar_context_empty_results($results);

    note 'Test scalar context with one index';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    is $results->rows, 1, '1 row returned';
    my $value = $results->one(1);
    is $value, 23, 'expected age returned';

    test_scalar_context_empty_results($results);

    note 'Test scalar context with multiple indexes throws';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    is $results->rows, 1, '1 row returned';
    throws_ok
        { $value = $results->one(2, 0) }
        qr/multiple indexes passed for single requested get value/,
        'one with multiple indexes in scalar context throws';

    note 'Test negative indexes';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    is $results->rows, 1, '1 row returned';
    my $favorite_food = $results->one(-1);
    is $favorite_food, 'Pizza', 'expected favorite food returned in scalar context using negative index';

    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    is $results->rows, 1, '1 row returned';
    $name = $results->one(-3);
    is $name, 'Bob', 'expected name returned in scalar context using negative index';

    test_scalar_context_empty_results($results);

    note 'Test valid indexes live';
    for my $index (-3..2) {
        $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                      ->with_roles($role)
                      ;

        is $results->rows, 1, '1 row returned';
        lives_ok { $value = $results->one($index) } "valid index '$index' lives";
    }

    note 'Test invalid indexes throw';
    for my $index (-5, -4, 3, 4) {
        $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                      ->with_roles($role)
                      ;

        is $results->rows, 1, '1 row returned';
        throws_ok
            { $value = $results->one($index) }
            qr/index out of valid range -3 to 2/,
            "invalid index '$index' throws";
    }

    note 'Test getting multiple rows';
    $db->insert(people => {name => 'Alice', age => 27, favorite_food => 'Hamburgers'});

    $results = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                  ->with_roles($role)
                  ;

    is $results->rows, 2, '2 rows returned';
    throws_ok
        { $name = $results->one }
        qr/multiple rows returned/,
        'test multiple rows throws';
}

sub test_scalar_context_empty_results {
    my ($results) = @_;

    throws_ok
        { my $value = $results->one }
        qr/no results/,
        'no results throws in scalar context';
}
