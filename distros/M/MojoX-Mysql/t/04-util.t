use Mojo::Base -strict;
use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Mojo::Util qw(dumper steady_time);
use FindBin;
use lib "$FindBin::Bin/../lib/";
use MojoX::Mysql;

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

ok($mysql->util->quote("test'test") eq "'test\\'test'", 'quote ok');
ok($mysql->util->quote() eq "DEFAULT", 'quote ok');
ok($mysql->util->quote('', 'NULL') eq "NULL", 'quote ok');

my $collection = $mysql->util->id;
$collection->each(sub {
	my $e = shift;
	ok($e == 1 || $e == 2, 'ok id');
});

done_testing();



