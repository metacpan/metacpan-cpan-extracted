use Mojo::Base -strict;
use Test::More;
use Mojo::mysql;
use Mojo::mysql::Database::Role::LoadDataInfile;

plan skip_all => q{TEST_ONLINE="mysql://root@/test;mysql_local_infile=1"} unless $ENV{TEST_ONLINE};

my $mysql = Mojo::mysql->new($ENV{TEST_ONLINE});
my $db = $mysql->db;
ok $db->ping, 'connected';

note 'Test rows with hashrefs and no provided columns';
$db->query('DROP TABLE IF EXISTS people');
$db->query(q{
    CREATE TABLE `people` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `name` VARCHAR(255) NOT NULL,
        `age` INT(11) NOT NULL,
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
    },
    {
        name => 'Alice',
        age => 27,
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

note 'Test rows with hashrefs and provided columns';
$db->query('DROP TABLE IF EXISTS people');
$db->query(q{
    CREATE TABLE `people` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `name` VARCHAR(255) NOT NULL,
        `age` INT(11) NOT NULL,
        `insert_time` DATETIME NULL DEFAULT NULL,
        PRIMARY KEY (`id`)
    )
    AUTO_INCREMENT=1
});
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

$people = [
    {
        id => 20, # should not be inserted
        name => 'Bob',
        age => 23,
        insert_time => '2012-08-25 14:22:34',
    },
    {
        id => 43, # should not be inserted
        name => 'Alice',
        age => 27,
    },
];

$res = $db->load_data_infile(table => 'people', rows => $people, columns => ['name', 'age', 'insert_time']);

is 2, $res->affected_rows, '2 affected rows';

# add values we expect to get back from DB but didn't use on insert
$people->[0]{id} = 1;
$people->[1]{id} = 2;
$people->[1]{insert_time} = '0000-00-00 00:00:00';

$people_from_db = $db->query('SELECT * FROM people ORDER BY id ASC')->hashes;
is_deeply $people_from_db, $people, 'expected values in db';

note 'Test rows with hashrefs and renamed columns';
$db->query('DROP TABLE IF EXISTS people');
$db->query(q{
    CREATE TABLE `people` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `name` VARCHAR(255) NOT NULL,
        `age` INT(11) NOT NULL,
        `insert_time` DATETIME NULL DEFAULT NULL,
        PRIMARY KEY (`id`)
    )
    AUTO_INCREMENT=1
});
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

$people = [
    {
        name => 'Bob',
        hash_age => 23,
    },
    {
        name => 'Alice',
        hash_age => 27,
    },
];

my $columns = ['name', { hash_age => 'age' }];
$res = $db->load_data_infile(table => 'people', rows => $people, columns => $columns);

is 2, $res->affected_rows, '2 affected rows';

# add values we expect to get back from DB but didn't use on insert
$people->[0]{id} = 1;
$people->[1]{id} = 2;
for my $person (@$people) {
    $person->{age} = delete $person->{hash_age};
    $person->{insert_time} = undef;
}

$people_from_db = $db->query('SELECT * FROM people ORDER BY id ASC')->hashes;
is_deeply $people_from_db, $people, 'expected values in db';

note 'Test columns with rows given arrayrefs';
$db->query('DROP TABLE IF EXISTS people');
$db->query(q{
    CREATE TABLE `people` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `name` VARCHAR(255) NOT NULL,
        `age` INT(11) NOT NULL,
        `insert_time` DATETIME NULL DEFAULT NULL,
        PRIMARY KEY (`id`)
    )
    AUTO_INCREMENT=1
});
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

my $expected_people = [
    {
        id => 1,
        name => 'Bob',
        age => 23,
        insert_time => undef,
    },
    {
        id => 2,
        name => 'Alice',
        age => 27,
        insert_time => undef,
    },
];
my $people_arrayrefs = [
    ['Bob', 23],
    ['Alice', 27],
];

$res = $db->load_data_infile(table => 'people', rows => $people_arrayrefs, columns => ['name', 'age']);

is 2, $res->affected_rows, '2 affected rows';

$people_from_db = $db->query('SELECT * FROM people ORDER BY id ASC')->hashes;
is_deeply $people_from_db, $expected_people, 'expected values in db';


note 'Test columns with unusual names';
$db->query('DROP TABLE IF EXISTS people');
$db->query(q{
    CREATE TABLE `people` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `the name` VARCHAR(255) NOT NULL,
        `the age` INT(11) NOT NULL,
        `insert_time` DATETIME NULL DEFAULT NULL,
        PRIMARY KEY (`id`)
    )
    AUTO_INCREMENT=1
});
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

$people = [
    {
        'the name' => 'Bob',
        'the age' => 23,
    },
    {
        'the name' => 'Alice',
        'the age' => 27,
    },
];

$res = $db->load_data_infile(table => 'people', rows => $people);

is 2, $res->affected_rows, '2 affected rows';

# add values we expect to get back from DB but didn't use on insert
$people->[0]{id} = 1;
$people->[1]{id} = 2;
$_->{insert_time} = undef for @$people;

$people_from_db = $db->query('SELECT * FROM people ORDER BY id ASC')->hashes;
is_deeply $people_from_db, $people, 'expected values in db';

done_testing;
