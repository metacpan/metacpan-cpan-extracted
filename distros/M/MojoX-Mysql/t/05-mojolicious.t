use Mojo::Base -strict;
use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Time::HiRes qw(gettimeofday);
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

plugin 'Mysql' => \%config;

get '/' => sub {
	my $self = shift;
	my $time = gettimeofday;

	my ($sth1,$dbh1) = $self->app->mysql->async(1)->query('SELECT SLEEP (?) as `sleep`', 1);
	my ($sth2,$dbh2) = $self->app->mysql->async(1)->query('SELECT SLEEP (?) as `sleep`', 1);

	$self->app->mysql->result->async($sth1,$dbh1);
	$self->app->mysql->result->async($sth2,$dbh2);

	$self->render(json=>{time=>int gettimeofday - $time});
	return;
};

my $t = Test::Mojo->new;
$t->get_ok('/');
$t->status_is(200);
$t->json_is({time=>1});

done_testing();
