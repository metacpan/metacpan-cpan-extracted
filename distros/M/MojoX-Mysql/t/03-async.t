use Mojo::Base -strict;
use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Mojo::Util qw(dumper steady_time);
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

my $time = steady_time;

my ($sth1,$dbh1) = $mysql->async(1)->query('SELECT SLEEP (?) as `sleep`', 1);
my ($sth2,$dbh2) = $mysql->async(1)->query('SELECT SLEEP (?) as `sleep`', 1);

$mysql->result->async($sth1,$dbh1);
$mysql->result->async($sth2,$dbh2);

$time = steady_time - $time;
ok($time < 2, 'ok async (total time <2 second)');

$time = steady_time;
my ($sth3,$dbh3) = $mysql->slave(1)->async(1)->query('SELECT SLEEP (?) as `sleep`', 1);
my ($sth4,$dbh4) = $mysql->slave(1)->async(1)->query('SELECT SLEEP (?) as `sleep`', 1);

$mysql->result->async($sth3,$dbh3);
$mysql->result->async($sth4,$dbh4);

$time = steady_time - $time;
ok($time < 2, 'ok async slave (total time <2 second)');

done_testing();




