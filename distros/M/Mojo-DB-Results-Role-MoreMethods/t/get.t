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
        test_list_context($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role, 'get');
        test_list_context($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role, 'get_or_die');

        test_scalar_context($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role, 'get');
        test_scalar_context($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role, 'get_or_die');
    }
}

done_testing;

sub test_list_context {
    my ($db, $drop_table_sql, $create_table_sql, $role, $method) = @_;
    my $die = $method eq 'get_or_die';

    ok $db->ping, 'connected';

    $db->query($drop_table_sql);
    $db->query($create_table_sql);
    $db->insert(people => {name => 'Bob', age => 23, favorite_food => 'Pizza'});

    note "Test calling $method in void context warns";
    my $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                     ->with_roles($role)
                     ;

    warning_like
        { $results->$method }
        qr/get or get variant called without using return value/,
        "$method called in void context warns";

    if ($die) {
        throws_ok
            { $results->$method }
            qr/no results/,
            "$method dies in void context when no results";
    } else {
        test_list_context_empty_results($results, $method, $die);
    }

    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;
    warning_like
        { $results->$method(0, 1, 2) }
        qr/get or get variant called without using return value/,
        "$method called with multiple indexes in void context warns";

    if ($die) {
        throws_ok
            { $results->$method(0, 1, 2) }
            qr/no results/,
            "$method dies in void context when no results and using multiple indexes";
    } else {
        test_list_context_empty_results($results, $method, $die);
    }

    note 'Test list context with no index';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    my ($name, $age, $favorite_food) = $results->$method;
    is $name, 'Bob', 'expected name returned in list context';
    is $age, 23, 'expected age returned in list context';
    is $favorite_food, 'Pizza', 'expected favorite food returned in list context';

    test_list_context_empty_results($results, $method, $die);

    note 'Test list context with one index';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    my @values = $results->$method(1);
    is scalar @values, 1, 'one value should be returned';
    is $values[0], 23, 'expected age returned';

    test_list_context_empty_results($results, $method, $die);

    note 'Test list context with multiple indexes';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    ($favorite_food, $name) = $results->$method(2, 0);
    is $favorite_food, 'Pizza', 'expected favorite food returned in list context using indexes';
    is $name, 'Bob', 'expected name returned in list context using indexes';

    test_list_context_empty_results($results, $method, $die);

    note 'Test negative indexes';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    ($favorite_food, $name) = $results->$method(-1, -3);
    is $favorite_food, 'Pizza', 'expected favorite food returned in list context using negative indexes';
    is $name, 'Bob', 'expected name returned in list context using negative indexes';

    test_list_context_empty_results($results, $method, $die);

    note 'Test valid indexes live';
    for my $index (-3..2) {
        $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                      ->with_roles($role)
                      ;
        lives_ok { @values = $results->$method($index) } "valid index '$index' lives";
    }

    note 'Test invalid indexes throw';
    for my $index (-5, -4, 3, 4) {
        $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                      ->with_roles($role)
                      ;
        throws_ok
            { @values = $results->$method($index) }
            qr/index out of valid range -3 to 2/,
            "invalid index '$index' throws";
    }

    note 'Test getting multiple rows';
    $db->insert(people => {name => 'Alice', age => 27, favorite_food => 'Hamburgers'});

    $results = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                  ->with_roles($role)
                  ;

    ($name, $age, $favorite_food) = $results->$method;
    is $name, 'Bob', 'expected name returned in list context';
    is $age, 23, 'expected age returned in list context';
    is $favorite_food, 'Pizza', 'expected favorite food returned in list context';

    ($name, $age, $favorite_food) = $results->$method;
    is $name, 'Alice', 'expected name returned in list context';
    is $age, 27, 'expected age returned in list context';
    is $favorite_food, 'Hamburgers', 'expected favorite food returned in list context';

    test_list_context_empty_results($results, $method, $die);
}

sub test_list_context_empty_results {
    my ($results, $method, $die) = @_;

    if ($die) {
        throws_ok
            { my @values = $results->$method }
            qr/no results/,
            'no results throws in list context';
    } else {
        my @values = $results->$method;
        ok @values == 0, "calling $method on empty results returns empty list";
    }
}

sub test_scalar_context {
    my ($db, $drop_table_sql, $create_table_sql, $role, $method) = @_;
    my $die = $method eq 'get_or_die';

    ok $db->ping, 'connected';

    $db->query($drop_table_sql);
    $db->query($create_table_sql);
    $db->insert(people => {name => 'Bob', age => 23, favorite_food => 'Pizza'});

    note "Test calling $method in void context warns";
    my $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                     ->with_roles($role)
                     ;

    warning_like
        { $results->$method }
        qr/get or get variant called without using return value/,
        "$method called in void context warns";

    if ($die) {
        throws_ok
            { $results->$method }
            qr/no results/,
            "$method dies in void context when no results";
    } else {
        test_scalar_context_empty_results($results, $method, $die);
    }

    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;
    warning_like
        { $results->$method(1) }
        qr/get or get variant called without using return value/,
        "$method called with index in void context warns";

    if ($die) {
        throws_ok
            { my $value = $results->$method(1) }
            qr/no results/,
            "$method dies in void context when no results and using index";
    } else {
        test_scalar_context_empty_results($results, $method, $die);
    }

    note 'Test scalar context with no index';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    my $name = $results->$method;
    is $name, 'Bob', 'expected name returned in scalar context';

    test_scalar_context_empty_results($results, $method, $die);

    note 'Test scalar context with one index';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    my $value = $results->$method(1);
    is $value, 23, 'expected age returned';

    test_scalar_context_empty_results($results, $method, $die);

    note 'Test scalar context with multiple indexes throws';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    throws_ok
        { $value = $results->$method(2, 0) }
        qr/multiple indexes passed for single requested get value/,
        "$method with multiple indexes in scalar context throws";

    note 'Test negative indexes';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    my $favorite_food = $results->$method(-1);
    is $favorite_food, 'Pizza', 'expected favorite food returned in scalar context using negative index';

    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;
    $name = $results->$method(-3);
    is $name, 'Bob', 'expected name returned in scalar context using negative index';

    test_scalar_context_empty_results($results, $method, $die);

    note 'Test valid indexes live';
    for my $index (-3..2) {
        $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                      ->with_roles($role)
                      ;
        lives_ok { $value = $results->$method($index) } "valid index '$index' lives";
    }

    note 'Test invalid indexes throw';
    for my $index (-5, -4, 3, 4) {
        $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                        ->with_roles($role)
                        ;
        throws_ok
            { $value = $results->$method($index) }
            qr/index out of valid range -3 to 2/,
            "invalid index '$index' throws";
    }

    note 'Test getting multiple rows';
    $db->insert(people => {name => 'Alice', age => 27, favorite_food => 'Hamburgers'});

    $results = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                  ->with_roles($role)
                  ;

    $name = $results->$method(0);
    is $name, 'Bob', 'expected name returned in scalar context';

    $name = $results->$method(0);
    is $name, 'Alice', 'expected name returned in scalar context';

    test_scalar_context_empty_results($results, $method, $die);
}

sub test_scalar_context_empty_results {
    my ($results, $method, $die) = @_;

    if ($die) {
        throws_ok
            { my $value = $results->$method }
            qr/no results/,
            'no results throws in scalar context';
    } else {
        my $value = $results->$method;
        is $value, undef, "calling $method on empty results returns undef in scalar context";
    }
}
