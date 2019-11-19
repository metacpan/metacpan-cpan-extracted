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
        `insert_time` DATETIME NULL DEFAULT NULL,
        PRIMARY KEY (`id`)
    )
    AUTO_INCREMENT=1
    PARTITION BY LIST(id) (
        PARTITION pOneThree VALUES IN (1, 3),
        PARTITION pTwo VALUES IN (2),
        PARTITION pFour VALUES IN (4)
    );
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
    {
        name => 'Eve',
        age => 19,
    },
];

my $res = $db->load_data_infile(table => 'people', rows => $people, partition => ['pOneThree', 'pTwo']);

is 3, $res->affected_rows, '3 affected rows';

# add values we expect to get back from DB but didn't use on insert
$people->[0]{id} = 1;
$people->[1]{id} = 2;
$people->[2]{id} = 3;
$_->{insert_time} = undef for @$people;

my @ponethree_people = @{$people}[0, 2];
my $people_from_db_ponethree = $db->query('SELECT * FROM people PARTITION (pOneThree) ORDER BY id ASC')->hashes;
is_deeply $people_from_db_ponethree, \@ponethree_people, 'extected pOneThree partition values';

my @ptwo_people = @{$people}[1];
my $people_from_db_ptwo = $db->query('SELECT * FROM people PARTITION (pTwo) ORDER BY id ASC')->hashes;
is_deeply $people_from_db_ptwo, \@ptwo_people, 'extected pTwo partition values';

is $db->query('SELECT COUNT(id) FROM people PARTITION (pFour)')->array->[0], 0, 'partition pFour is empty';


note 'Test partitions with unusual names';
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
    PARTITION BY LIST(id) (
        PARTITION `p one three` VALUES IN (1, 3),
        PARTITION `p two` VALUES IN (2),
        PARTITION `p four` VALUES IN (4)
    );
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
    {
        name => 'Eve',
        age => 19,
    },
];

$res = $db->load_data_infile(table => 'people', rows => $people, partition => ['p one three', 'p two']);

is 3, $res->affected_rows, '3 affected rows';

# add values we expect to get back from DB but didn't use on insert
$people->[0]{id} = 1;
$people->[1]{id} = 2;
$people->[2]{id} = 3;
$_->{insert_time} = undef for @$people;

@ponethree_people = @{$people}[0, 2];
$people_from_db_ponethree = $db->query('SELECT * FROM people PARTITION (`p one three`) ORDER BY id ASC')->hashes;
is_deeply $people_from_db_ponethree, \@ponethree_people, 'extected `p one three` partition values';

@ptwo_people = @{$people}[1];
$people_from_db_ptwo = $db->query('SELECT * FROM people PARTITION (`p two`) ORDER BY id ASC')->hashes;
is_deeply $people_from_db_ptwo, \@ptwo_people, 'extected `p two` partition values';

is $db->query('SELECT COUNT(id) FROM people PARTITION (`p four`)')->array->[0], 0, 'partition `p four` is empty';

done_testing;
