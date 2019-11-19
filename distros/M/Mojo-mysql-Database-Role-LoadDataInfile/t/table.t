use Mojo::Base -strict;
use Test::More;
use Mojo::mysql;
use Mojo::mysql::Database::Role::LoadDataInfile;

plan skip_all => q{TEST_ONLINE="mysql://root@/test;mysql_local_infile=1"} unless $ENV{TEST_ONLINE};

my $mysql = Mojo::mysql->new($ENV{TEST_ONLINE});
my $db = $mysql->db;
ok $db->ping, 'connected';

note 'Test unusual table name';
$db->query('DROP TABLE IF EXISTS `the people`');
$db->query(q{
    CREATE TABLE `the people` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `name` VARCHAR(255) NOT NULL,
        `age` INT(11) NOT NULL,
        `insert_time` DATETIME NULL DEFAULT NULL,
        PRIMARY KEY (`id`)
    )
    AUTO_INCREMENT=1
});

is $db->query('SELECT COUNT(id) FROM `the people`')->array->[0], 0, '`the people` table is empty';

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

my $res = $db->load_data_infile(table => 'the people', rows => $people);

is 2, $res->affected_rows, '2 affected rows';

# add values we expect to get back from DB but didn't use on insert
$people->[0]{id} = 1;
$people->[1]{id} = 2;
$_->{insert_time} = undef for @$people;

my $people_from_db = $db->query('SELECT * FROM `the people` ORDER BY id ASC')->hashes;
is_deeply $people_from_db, $people, 'expected values in db';

done_testing;
