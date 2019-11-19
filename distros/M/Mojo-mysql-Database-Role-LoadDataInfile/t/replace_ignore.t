use Mojo::Base -strict;
use Test::More;
use Mojo::mysql;
use Mojo::mysql::Database::Role::LoadDataInfile;

plan skip_all => q{TEST_ONLINE="mysql://root@/test;mysql_local_infile=1"} unless $ENV{TEST_ONLINE};

my $mysql = Mojo::mysql->new($ENV{TEST_ONLINE});
my $db = $mysql->db;
ok $db->ping, 'connected';

$db->query('DROP TABLE IF EXISTS people');
$db->query(q{
    CREATE TABLE `people` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `name` VARCHAR(255) NOT NULL,
        `age` INT(11) NOT NULL,
        `favorite_food` VARCHAR(255) NOT NULL,
        `insert_time` DATETIME NULL DEFAULT NULL,
        PRIMARY KEY (`id`)
    )
    AUTO_INCREMENT=1
});

is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

my $people = [
    {
        name => 'Bob',
        age => 23,
        favorite_food => 'Pizza',
    },
    {
        name => 'Alice',
        age => 27,
        favorite_food => 'Tacos',
    },
];

my $res = $db->load_data_infile(table => 'people', rows => $people);

is 2, $res->affected_rows, '2 affected rows';

# add values we expect to get back from DB but didn't use on insert
$people->[0]{id} = 1;
$people->[1]{id} = 2;
$_->{insert_time} = undef for @$people;

my $people_from_db = $db->query('SELECT * FROM people ORDER BY id ASC')->hashes;
is_deeply $people_from_db, $people, 'expected values in db';

note 'Test rows do not change when ignore is set';
my $people_with_new_favorite_foods = [
    {
        %{ $people->[0] },
        favorite_food => 'Cheeseburgers',
    },
    {
        %{ $people->[1] },
        favorite_food => 'Hot Dogs',
    },
];
delete $_->{insert_time} for @$people_with_new_favorite_foods;

$res = $db->load_data_infile(table => 'people', rows => $people_with_new_favorite_foods, ignore => 1);

is 0, $res->affected_rows, '0 affected rows';

$people_from_db = $db->query('SELECT * FROM people ORDER BY id ASC')->hashes;
is_deeply $people_from_db, $people, 'expected values in db';

note 'Test rows do not change with implicit ignore';
$res = $db->load_data_infile(table => 'people', rows => $people_with_new_favorite_foods);

is 0, $res->affected_rows, '0 affected rows';

$people_from_db = $db->query('SELECT * FROM people ORDER BY id ASC')->hashes;
is_deeply $people_from_db, $people, 'expected values in db';

note 'Test rows do change when replace is set';
$res = $db->load_data_infile(table => 'people', rows => $people_with_new_favorite_foods, replace => 1);

# four affected rows are expected: two original rows deleted, two new rows added
is 4, $res->affected_rows, '4 affected rows';

$_->{insert_time} = undef for @$people_with_new_favorite_foods;

$people_from_db = $db->query('SELECT * FROM people ORDER BY id ASC')->hashes;
is_deeply $people_from_db, $people_with_new_favorite_foods, 'new rows equal because they were updated';

done_testing;
