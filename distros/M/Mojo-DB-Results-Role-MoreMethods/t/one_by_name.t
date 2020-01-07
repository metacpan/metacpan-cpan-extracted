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

    note 'Test calling one_by_name in void context warns';
    my $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                     ->with_roles($role)
                     ;

    is $results->rows, 1, '1 row returned';
    warning_like
        { $results->one_by_name('name') }
        qr/get or get variant called without using return value/,
        'one_by_name called in void context warns';

    test_list_context_empty_results($results);

    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    is $results->rows, 1, '1 row returned';
    warning_like
        { $results->one_by_name('name', 'age', 'favorite_food') }
        qr/get or get variant called without using return value/,
        'one_by_name called with multiple names in void context warns';

    test_list_context_empty_results($results);

    note 'Test list context with no names';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    is $results->rows, 1, '1 row returned';
    throws_ok
        { my @values = $results->one_by_name }
        qr/names required/,
        'no names throws in list context';

    note 'Test list context with one name';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    is $results->rows, 1, '1 row returned';
    my @values = $results->one_by_name('age');
    is scalar @values, 1, 'one value should be returned';
    is $values[0], 23, 'expected age returned';

    test_list_context_empty_results($results);

    note 'Test list context with multiple names';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    is $results->rows, 1, '1 row returned';
    my ($favorite_food, $name) = $results->one_by_name('favorite_food', 'name');
    is $favorite_food, 'Pizza', 'expected favorite food returned in list context using names';
    is $name, 'Bob', 'expected name returned in list context using names';

    test_list_context_empty_results($results);

    note 'Test unknown column';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;
    throws_ok
        { $results->one_by_name('catch_phrase') }
        qr/could not find column 'catch_phrase' in returned columns/,
        'unknown column name throws';

    note 'Test getting multiple rows';
    $db->insert(people => {name => 'Alice', age => 27, favorite_food => 'Hamburgers'});

    $results = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                  ->with_roles($role)
                  ;

    is $results->rows, 2, '2 rows returned';

    my $age;
    throws_ok
        { ($name, $age, $favorite_food) = $results->one_by_name('name', 'age', 'favorite_food') }
        qr/multiple rows returned/,
        'multiple rows returned throws';
}

sub test_list_context_empty_results {
    my ($results) = @_;

    throws_ok
        { my @values = $results->one_by_name('name') }
        qr/no results/,
        'no results throws in list context';
}

sub test_scalar_context {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;
    ok $db->ping, 'connected';

    $db->query($drop_table_sql);
    $db->query($create_table_sql);
    $db->insert(people => {name => 'Bob', age => 23, favorite_food => 'Pizza'});

    note 'Test calling one_by_name in void context warns';
    my $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                     ->with_roles($role)
                     ;

    is $results->rows, 1, '1 row returned';
    warning_like
        { $results->one_by_name('name') }
        qr/get or get variant called without using return value/,
        'one_by_name called in void context warns';

    test_scalar_context_empty_results($results);

    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    is $results->rows, 1, '1 row returned';
    warning_like
        { $results->one_by_name('name', 'age', 'favorite_food') }
        qr/get or get variant called without using return value/,
        'one_by_name called with multiple names in void context warns';

    test_scalar_context_empty_results($results);

    note 'Test scalar context with no names';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    is $results->rows, 1, '1 row returned';
    throws_ok
        { my $value = $results->one_by_name }
        qr/names required/,
        'no names throws in scalar context';

    note 'Test scalar context with one name';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    is $results->rows, 1, '1 row returned';
    my $value = $results->one_by_name('age');
    is $value, 23, 'expected age returned';

    test_scalar_context_empty_results($results);

    note 'Test scalar context with multiple names throws';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    is $results->rows, 1, '1 row returned';
    throws_ok
        { $value = $results->one_by_name('name', 'age') }
        qr/multiple indexes passed for single requested get value/,
        'one_by_name with multiple names in scalar context throws';

    note 'Test unknown column';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    is $results->rows, 1, '1 row returned';
    throws_ok
        { $results->one_by_name('catch_phrase') }
        qr/could not find column 'catch_phrase' in returned columns/,
        'unknown column name throws';

    note 'Test getting multiple rows';
    $db->insert(people => {name => 'Alice', age => 27, favorite_food => 'Hamburgers'});

    $results = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                  ->with_roles($role)
                  ;

    is $results->rows, 2, '2 rows returned';
    throws_ok
        { my $name = $results->one_by_name('name') }
        qr/multiple rows returned/,
        'multiple rows returned throws';
}

sub test_scalar_context_empty_results {
    my ($results) = @_;

    throws_ok
        { my $value = $results->one_by_name('name') }
        qr/no results/,
        'no results throws in scalar context';
}
