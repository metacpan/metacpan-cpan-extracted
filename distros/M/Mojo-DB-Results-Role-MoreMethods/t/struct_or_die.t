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
        ok $db->ping, 'connected';

        $db->query($mojo_db_config->{drop_table_sql});
        $db->query($mojo_db_config->{create_table_sql});
        $db->insert(people => {name => 'Bob', age => 23, favorite_food => 'Pizza'});

        note 'Test calling struct_or_die in void context warns';
        my $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                         ->with_roles($role)
                         ;

        warning_like
            { $results->struct_or_die }
            qr/struct_or_die called without using return value/,
            'struct_or_die called in void context warns';

        test_empty_results_dies($results);

        note 'Test zero rows returned';
        $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => -1})
                       ->with_roles($role)
                       ;

        test_empty_results_dies($results);

        note 'Test returning single row';
        $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                       ->with_roles($role)
                       ;

        my $struct = $results->struct_or_die;
        is $struct->name, 'Bob', 'expected name returned';
        is $struct->age, 23, 'expected age returned';
        is $struct->favorite_food, 'Pizza', 'expected favorite food returned';

        test_empty_results_dies($results);

        note 'Test struct with one returned column';
        $results = $db->select(people => 'age' => {id => 1})
                      ->with_roles($role)
                      ;

        $struct = $results->struct_or_die;
        is $struct->age, 23, 'expected age returned';

        test_empty_results_dies($results);

        note 'Test getting multiple rows';
        $db->insert(people => {name => 'Alice', age => 27, favorite_food => 'Hamburgers'});

        $results = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                      ->with_roles($role)
                      ;

        $struct = $results->struct_or_die;
        is $struct->name, 'Bob', 'expected name returned';
        is $struct->age, 23, 'expected age returned';
        is $struct->favorite_food, 'Pizza', 'expected favorite food returned';

        $struct = $results->struct_or_die;
        is $struct->name, 'Alice', 'expected name returned';
        is $struct->age, 27, 'expected age returned';
        is $struct->favorite_food, 'Hamburgers', 'expected favorite food returned';

        test_empty_results_dies($results);
    }
}

done_testing;

sub test_empty_results_dies {
    my ($results) = @_;

    throws_ok
        { my $struct = $results->struct_or_die }
        qr/no results/,
        'no results throws';
}
