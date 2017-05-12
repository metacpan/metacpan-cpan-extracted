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
	  `datetime` datetime NOT NULL,
	  PRIMARY KEY (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='test table' AUTO_INCREMENT=1;
});

my ($insertid,$counter) = $mysql->do('INSERT INTO `test` (`datetime`) VALUES("2001-01-01 00:00:00")');
ok($insertid == 1, 'insertid');

my $result = $mysql->query('SELECT `datetime` FROM `test` WHERE `id` = ? LIMIT 1', $insertid);
$result->each(sub{
	my $e = shift;
	ok($e->{'datetime'}->to_string eq 'Mon, 01 Jan 2001 00:00:00 GMT');
});


$mysql->do('DROP TABLE IF EXISTS `test`;'); # Delete table

$mysql->do(q{
	CREATE TABLE IF NOT EXISTS `test` (
	  `id` int(11) NOT NULL AUTO_INCREMENT,
	  `int` tinyint(1) unsigned NULL DEFAULT 0,
	  PRIMARY KEY (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='test table' AUTO_INCREMENT=1;
});

($insertid,$counter) = $mysql->do('INSERT INTO `test` (`int`) VALUES(0)');
$result = $mysql->query('SELECT `int` FROM `test` WHERE `id` = ? LIMIT 1', $insertid);
$result->each(sub{
	my $e = shift;
	ok($e->{'int'} == 0, 'ok 0');
});


$mysql->do('DROP TABLE IF EXISTS `test`;'); # Delete table
$mysql->do(q{
	CREATE TABLE IF NOT EXISTS `test` (
	  `id` int(11) NOT NULL AUTO_INCREMENT,
	  `int` tinyint(1) unsigned NULL DEFAULT 0,
	  PRIMARY KEY (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='test table' AUTO_INCREMENT=1;
});
($insertid,$counter) = $mysql->do('INSERT INTO `test` (`int`) VALUES(1)');
$result = $mysql->query('SELECT `int` FROM `test` WHERE `id` = ? LIMIT 1', $insertid);
$result->each(sub{
	my $e = shift;
	ok($e->{'int'} == 1, 'ok 1');
});




done_testing();
