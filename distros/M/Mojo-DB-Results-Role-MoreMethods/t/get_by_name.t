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
        test_list_context($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role, 'get_by_name');
        test_list_context($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role, 'get_by_name_or_die');

        test_scalar_context($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role, 'get_by_name');
        test_scalar_context($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role, 'get_by_name_or_die');
    }
}

done_testing;

sub test_list_context {
    my ($db, $drop_table_sql, $create_table_sql, $role, $method) = @_;
    my $die = $method eq 'get_by_name_or_die';

    ok $db->ping, 'connected';

    $db->query($drop_table_sql);
    $db->query($create_table_sql);
    $db->insert(people => {name => 'Bob', age => 23, favorite_food => 'Pizza'});

    note "Test calling $method in void context warns";
    my $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                     ->with_roles($role)
                     ;

    warning_like
        { $results->$method('name') }
        qr/get or get variant called without using return value/,
        "$method called in void context warns";

    if ($die) {
        throws_ok
            { $results->$method('name') }
            qr/no results/,
            "$method dies in void context when no results";
    } else {
        test_list_context_empty_results($results, $method, $die);
    }

    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;
    warning_like
        { $results->$method('name', 'age', 'favorite_food') }
        qr/get or get variant called without using return value/,
        "$method called with multiple names in void context warns";

    if ($die) {
        throws_ok
            { $results->$method('name', 'age', 'favorite_food') }
            qr/no results/,
            "$method dies in void context when no results and using names";
    } else {
        test_list_context_empty_results($results, $method, $die);
    }

    note 'Test list context with no names';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    throws_ok
        { my @values = $results->$method }
        qr/names required/,
        'no names throws in list context';

    note 'Test list context with one name';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    my @values = $results->$method('age');
    is scalar @values, 1, 'one value should be returned';
    is $values[0], 23, 'expected age returned';

    test_list_context_empty_results($results, $method, $die);

    note 'Test list context with multiple names';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    my ($favorite_food, $name) = $results->$method('favorite_food', 'name');
    is $favorite_food, 'Pizza', 'expected favorite food returned in list context using names';
    is $name, 'Bob', 'expected name returned in list context using names';

    test_list_context_empty_results($results, $method, $die);

    note 'Test unknown column';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;
    throws_ok
        { $results->$method('catch_phrase') }
        qr/could not find column 'catch_phrase' in returned columns/,
        'unknown column name throws';

    note 'Test getting multiple rows';
    $db->insert(people => {name => 'Alice', age => 27, favorite_food => 'Hamburgers'});

    $results = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                  ->with_roles($role)
                  ;

    my $age;
    ($name, $age, $favorite_food) = $results->$method('name', 'age', 'favorite_food');
    is $name, 'Bob', 'expected name returned in list context';
    is $age, 23, 'expected age returned in list context';
    is $favorite_food, 'Pizza', 'expected favorite food returned in list context';

    ($name, $age, $favorite_food) = $results->$method('name', 'age', 'favorite_food');
    is $name, 'Alice', 'expected name returned in list context';
    is $age, 27, 'expected age returned in list context';
    is $favorite_food, 'Hamburgers', 'expected favorite food returned in list context';

    test_list_context_empty_results($results, $method, $die);
}

sub test_list_context_empty_results {
    my ($results, $method, $die) = @_;

    if ($die) {
        throws_ok
            { my @values = $results->$method('name') }
            qr/no results/,
            'no results throws in list context';
    } else {
        my @values = $results->$method('name');
        ok @values == 0, "calling $method on empty results returns empty list";
    }
}

sub test_scalar_context {
    my ($db, $drop_table_sql, $create_table_sql, $role, $method) = @_;
    my $die = $method eq 'get_by_name_or_die';

    ok $db->ping, 'connected';

    $db->query($drop_table_sql);
    $db->query($create_table_sql);
    $db->insert(people => {name => 'Bob', age => 23, favorite_food => 'Pizza'});

    note "Test calling $method in void context warns";
    my $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                     ->with_roles($role)
                     ;

    warning_like
        { $results->$method('name') }
        qr/get or get variant called without using return value/,
        "$method called in void context warns";

    if ($die) {
        throws_ok
            { $results->$method('name') }
            qr/no results/,
            "$method dies in void context when no results";
    } else {
        test_scalar_context_empty_results($results, $method, $die);
    }

    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;
    warning_like
        { $results->$method('name', 'age', 'favorite_food') }
        qr/get or get variant called without using return value/,
        "$method called with multiple names in void context warns";

    if ($die) {
        throws_ok
            { $results->$method('name', 'age', 'favorite_food') }
            qr/no results/,
            "$method dies in void context when no results and using names";
    } else {
        test_scalar_context_empty_results($results, $method, $die);
    }

    note 'Test scalar context with no names';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    throws_ok
        { my $value = $results->$method }
        qr/names required/,
        'no names throws in scalar context';

    note 'Test scalar context with one name';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    my $value = $results->$method('age');
    is $value, 23, 'expected age returned';

    test_scalar_context_empty_results($results, $method, $die);

    note 'Test scalar context with multiple names warns';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    throws_ok
        { $value = $results->$method('name', 'age') }
        qr/multiple indexes passed for single requested get value/,
        "$method with multiple names in scalar context throws";

    note 'Test unknown column';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;
    throws_ok
        { $results->$method('catch_phrase') }
        qr/could not find column 'catch_phrase' in returned columns/,
        'unknown column name throws';

    note 'Test getting multiple rows';
    $db->insert(people => {name => 'Alice', age => 27, favorite_food => 'Hamburgers'});

    $results = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                  ->with_roles($role)
                  ;

    my $name = $results->$method('name');
    is $name, 'Bob', 'expected name returned in scalar context';

    $name = $results->$method('name');
    is $name, 'Alice', 'expected name returned in scalar context';

    test_scalar_context_empty_results($results, $method, $die);
}

sub test_scalar_context_empty_results {
    my ($results, $method, $die) = @_;

    if ($die) {
        throws_ok
            { my $value = $results->$method('name') }
            qr/no results/,
            'no results throws in scalar context';
    } else {
        my $value = $results->$method('name');
        is $value, undef, "calling $method on empty results returns undef in scalar context";
    }
}
