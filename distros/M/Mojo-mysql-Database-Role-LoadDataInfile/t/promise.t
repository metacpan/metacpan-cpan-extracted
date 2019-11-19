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

my $promise = $db->load_data_infile_p(table => 'people', rows => $people);
isa_ok($promise, 'Mojo::Promise');

is $db->backlog, 1, 'one operation waiting';
Mojo::IOLoop->start;
is $db->backlog, 0, 'no operations waiting';

my ($res, $err);
$promise->then(sub {
    $res = shift;
})->catch(sub {
    $err = shift;
})->wait;

ok !$err, 'no error' or diag "err=$err";
is 2, $res->affected_rows, '2 affected rows';

# add values we expect to get back from DB but didn't use on insert
$people->[0]{id} = 1;
$people->[1]{id} = 2;
$_->{insert_time} = undef for @$people;

my $people_from_db = $db->query('SELECT * FROM people ORDER BY id ASC')->hashes;
is_deeply $people_from_db, $people, 'expected values in db';

note 'Promises (rejected)';
my $fail;
$db->load_data_infile_p(table => 'dont_exist', rows => $people)->catch(sub { $fail = shift })->wait;
like $fail, qr/dont_exist/, 'right error';

note 'Avoid "Calling a synchronous function on an asynchronous handle"';
$promise = $db->load_data_infile_p(table => 'people', rows => $people);
eval { $db->load_data_infile(table => 'people', rows => $people) };
like $@, qr{Cannot perform blocking query, while waiting for async response},
  'Cannot perform blocking and non-blocking at the same time';

done_testing;
