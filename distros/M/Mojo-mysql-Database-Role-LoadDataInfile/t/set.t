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
        `favorite_number` INT(11) NULL,
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

my $res = $db->load_data_infile(table => 'people', rows => $people, set => [{favorite_number => '1+1'}]);

is 2, $res->affected_rows, '2 affected rows';

# add values we expect to get back from DB but didn't use on insert
$people->[0]{id} = 1;
$people->[1]{id} = 2;
$_->{favorite_number} = 2 for @$people;

my $people_from_db = $db->query('SELECT * FROM people ORDER BY id ASC')->hashes;
is_deeply $people_from_db, $people, 'expected values in db';

note 'Test set with columns with unusual names';
$db->query('DROP TABLE IF EXISTS people');
$db->query(q{
    CREATE TABLE `people` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `name` VARCHAR(255) NOT NULL,
        `age` INT(11) NOT NULL,
        `the favorite number` INT(11) NULL,
        PRIMARY KEY (`id`)
    )
    AUTO_INCREMENT=1
});

is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

$people = [
    {
        name => 'Bob',
        age => 23,
    },
    {
        name => 'Alice',
        age => 27,
    },
];

$res = $db->load_data_infile(table => 'people', rows => $people, set => [{'the favorite number' => '1+1'}]);

is 2, $res->affected_rows, '2 affected rows';

# add values we expect to get back from DB but didn't use on insert
$people->[0]{id} = 1;
$people->[1]{id} = 2;
$_->{'the favorite number'} = 2 for @$people;

$people_from_db = $db->query('SELECT * FROM people ORDER BY id ASC')->hashes;
is_deeply $people_from_db, $people, 'expected values in db';

done_testing;
