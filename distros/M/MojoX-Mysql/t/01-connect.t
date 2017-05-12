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

my $dbh = $mysql->db->connect_master;
ok($dbh->ping == 1, 'ping ok');

$dbh = $mysql->db->connect_slave;
ok($dbh->ping == 1, 'ping ok slave');

for my $id (1..2){
	my $dbh = $mysql->db->id($id)->connect_master;
	ok($dbh->ping == 1, 'ping ok '.$id);

	$dbh = $mysql->db->id($id)->connect_slave;
	ok($dbh->ping == 1, 'ping ok slave '.$id);
}

done_testing();



