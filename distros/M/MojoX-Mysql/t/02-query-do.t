use Mojo::Base -strict;
use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Mojo::Util qw(dumper);
use FindBin;
use lib "$FindBin::Bin/../lib/";
use MojoX::Mysql;

plan skip_all => 'set MOJO_TEST_TRAVIS to enable this test' unless $ENV{'MOJO_TEST_TRAVIS'};

my %config = (
	user=>'root',
	password=>undef,
	server=>[
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'master'},
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'slave'},
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>1, type=>'master'},
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>1, type=>'slave'},
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>2, type=>'master'},
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>2, type=>'slave'},
	]
);
$config{'user'} = 'root' if(defined $ENV{'MOJO_TEST_TRAVIS'} && $ENV{'MOJO_TEST_TRAVIS'} == 1);

my $mysql = MojoX::Mysql->new(%config);
$mysql->do('DROP TABLE IF EXISTS `test`;'); # Delete table

$mysql->do(q{
	CREATE TABLE IF NOT EXISTS `test` (
	  `id` int(11) NOT NULL AUTO_INCREMENT,
	  `text` varchar(200) NOT NULL,
	  PRIMARY KEY (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='test table' AUTO_INCREMENT=1;
});

my ($insertid,$counter) = $mysql->do('INSERT INTO `test` (`text`) VALUES(?)', 'Привет как дела');
ok($insertid == 1, 'insertid');
ok($counter == 1, 'counter');

$insertid = $mysql->do('INSERT INTO `test` (`text`) VALUES(?)', 'Привет как дела');
ok($insertid == 2, 'insertid');

my $result = $mysql->query('SELECT `text` FROM `test` WHERE `id` = ? LIMIT 1', $insertid);
$result->each(sub{
	my $e = shift;
	ok($e->{'text'} eq 'Привет как дела', 'text');
});

$result->map(sub {
	ok(shift->{'text'} eq 'Привет как дела', 'text');
});

$result = $mysql->id(1)->slave(1)->query('SELECT VERSION() as `version`;');
$result->map(sub {
	like(shift->{'version'}, qr/^5.5/, 'check version');
});

$mysql->query('SELECT `text` FROM `test` WHERE `id` = ? LIMIT 1', $insertid, sub{
	my ($self,$data) = @_;
	ok($data->{'text'} eq 'Привет как дела', 'text');
});

$mysql->db->commit;
$mysql->db->disconnect;

done_testing();




