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
});

is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

is $db->backlog, 0, 'no operations waiting';

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

my ($cb_db, $err, $res);
$db->load_data_infile(table => 'people', rows => $people, sub { ($cb_db, $err, $res) = @_; Mojo::IOLoop->stop; });

is $db->backlog, 1, 'one operation waiting';
Mojo::IOLoop->start;
is $db->backlog, 0, 'no operations waiting';

is $cb_db, $db, 'db in callback is expected db';
ok !$err, 'no error' or diag "err=$err";
is 2, $res->affected_rows, '2 affected rows';

# add values we expect to get back from DB but didn't use on insert
$people->[0]{id} = 1;
$people->[1]{id} = 2;
$_->{insert_time} = undef for @$people;

my $people_from_db = $db->query('SELECT * FROM people ORDER BY id ASC')->hashes;
is_deeply $people_from_db, $people, 'expected values in db';

note 'Non-blocking error';
($err, $res) = ();
$db->load_data_infile(table => 'dont_exist', rows => $people, sub { ($cb_db, $err, $res) = @_; Mojo::IOLoop->stop; });
Mojo::IOLoop->start;
like $err, qr/dont_exist/, 'dont_exist async';

done_testing;
