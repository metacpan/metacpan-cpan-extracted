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
        test_method($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role, 'c_by_name');
        test_method($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role, 'c_by_name_or_die');
    }
}

done_testing;

sub test_method {
    my ($db, $drop_table_sql, $create_table_sql, $role, $method) = @_;
    my $die = $method eq 'c_by_name_or_die';

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
        test_empty_results($results, $method, $die);
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
        test_empty_results($results, $method, $die);
    }

    note 'Test with no names';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    throws_ok
        { my $c = $results->$method }
        qr/names required/,
        'no names throws';

    note 'Test with one name';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    my $c = $results->$method('age');
    isa_ok $c, 'Mojo::Collection';

    is $c->size, 1, 'one value returned';
    is scalar @$c, 1, 'one value returned';
    is $c->[0], 23, 'expected age returned';

    test_empty_results($results, $method, $die);

    note 'Test with multiple names';
    $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                  ->with_roles($role)
                  ;

    $c = $results->$method('favorite_food', 'name');
    isa_ok $c, 'Mojo::Collection';

    is $c->size, 2, 'two values returned';
    is scalar @$c, 2, 'two values returned';
    is $c->[0], 'Pizza', 'expected favorite food returned';
    is $c->[1], 'Bob', 'expected name returned';

    test_empty_results($results, $method, $die);

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

    $c = $results->$method('name', 'age', 'favorite_food');
    isa_ok $c, 'Mojo::Collection';

    is $c->size, 3, 'three values returned';
    is scalar @$c, 3, 'three values returned';
    is $c->[0], 'Bob', 'expected name returned';
    is $c->[1], 23, 'expected age returned';
    is $c->[2], 'Pizza', 'expected favorite food returned';

    $c = $results->$method('name', 'age', 'favorite_food');
    isa_ok $c, 'Mojo::Collection';

    is $c->size, 3, 'three values returned';
    is scalar @$c, 3, 'three values returned';
    is $c->[0], 'Alice', 'expected name returned';
    is $c->[1], 27, 'expected age returned';
    is $c->[2], 'Hamburgers', 'expected favorite food returned';

    test_empty_results($results, $method, $die);
}

sub test_empty_results {
    my ($results, $method, $die) = @_;

    if ($die) {
        throws_ok
            { my $c = $results->$method('name') }
            qr/no results/,
            'no results throws';
    } else {
        my $c = $results->$method('name');
        is $c, undef, "calling $method on empty results returns undef";
    }
}
