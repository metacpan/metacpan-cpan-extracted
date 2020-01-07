use Mojo::Base -strict;
use Test::More;
use Test::Exception;

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
        $db->insert(people => {name => 'Alice', age => 27, favorite_food => 'Hamburgers'});
        $db->insert(people => {name => 'Eve', age => 33, favorite_food => 'Sushi'});

        note 'Test 0 rows returned';
        my $results = $db->select(people => '*' => {id => 4})->with_roles($role);
        is $results->rows, 0, '0 rows returned';
        throws_ok
            { $results->one_array }
            qr/no rows returned/,
            '0 rows returned throws';

        note 'Test 2 rows returned';
        $results = $db->select(people => '*' => {id => {-in => [1, 2]}})->with_roles($role);
        is $results->rows, 2, '2 rows returned';
        throws_ok
            { $results->one_array }
            qr/multiple rows returned/,
            '2 rows returned throws';

        note 'Test 3 rows returned';
        $results = $db->select(people => '*' => {id => {-in => [1, 2, 3]}})->with_roles($role);
        is $results->rows, 3, '3 rows returned';
        throws_ok
            { $results->one_array }
            qr/multiple rows returned/,
            '3 rows returned throws';

        note 'Test 1 row returned';
        $results = $db->select(people => '*' => {id => 1})->with_roles($role);
        is $results->rows, 1, '1 row returned';

        my $array;
        lives_ok
            { $array = $results->one_array }
            '1 row returned lives';
        is_deeply $array, [1, 'Bob', 23, 'Pizza'];
    }
}

done_testing;
