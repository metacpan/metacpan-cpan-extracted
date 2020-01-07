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

        my $bob = {name => 'Bob', age => 23, favorite_food => 'Pizza'};
        $db->insert(people => $bob);

        note 'Test calling hash_or_die in void context warns';
        my $results = $db->select(people => ['name', 'age', 'favorite_food'] => {id => 1})
                         ->with_roles($role)
                         ;

        warning_like
            { $results->hash_or_die }
            qr/hash_or_die called without using return value/,
            'hash_or_die called in void context warns';

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

        is_deeply $results->hash_or_die, $bob, 'expected values returned';

        test_empty_results_dies($results);

        note 'Test hash with one returned column';
        $results = $db->select(people => 'age' => {id => 1})
                      ->with_roles($role)
                      ;

        is_deeply $results->hash_or_die, {age => 23}, 'expected age returned';

        test_empty_results_dies($results);

        note 'Test getting multiple rows';
        my $alice = {name => 'Alice', age => 27, favorite_food => 'Hamburgers'};
        $db->insert(people => $alice);

        $results = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                      ->with_roles($role)
                      ;

        is_deeply $results->hash_or_die, $bob, 'expected values returned';
        is_deeply $results->hash_or_die, $alice, 'expected values returned';

        test_empty_results_dies($results);
    }
}

done_testing;

sub test_empty_results_dies {
    my ($results) = @_;

    throws_ok
        { my $hash = $results->hash_or_die }
        qr/no results/,
        'no results throws';
}
