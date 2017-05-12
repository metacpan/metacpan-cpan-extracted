use Mojo::Base -strict;
use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Time::HiRes qw(gettimeofday);
use Mojo::Util qw(dumper steady_time);
use FindBin;
use lib "$FindBin::Bin/../lib/";
use MojoX::Tree;

my %config = (
	user=>'root',
	password=>undef,
	server=>[
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'master'},
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'slave'},
	]
);
$config{'user'} = 'travis' if(defined $ENV{'USER'} && $ENV{'USER'} eq 'travis');

plugin 'Mysql' => \%config;
plugin 'Tree' => {namespace=>'obj1', table=>'tree', length=>10, column=>{id=>'tree_id', name=>'name', path=>'path', level=>'level', parent_id=>'parent_id'}};
plugin 'Tree' => {namespace=>'obj2', table=>'tree', length=>10, column=>{id=>'tree_id', name=>'name', path=>'path', level=>'level', parent_id=>'parent_id'}};

get '/' => sub {
	my $self = shift;
	my $time = gettimeofday;
	my $obj1 = $self->tree->obj1;
	my $obj2 = $self->tree->obj2;
	$self->render(json=>{obj1=>ref $obj1, obj2=>ref $obj2});
	return;
};

my $t = Test::Mojo->new;
$t->get_ok('/');
$t->status_is(200);
$t->json_is({obj1=>'MojoX::Tree', obj2=>'MojoX::Tree'});


done_testing();
