use Mojo::Base 'Mojolicious';
use Test::More;
use Test::Mojo;
use DBI;

plan skip_all => 'set env TEST_CONN_PG="DBI:Pg:dbname=<db>/<pg_user>/<passwd>" to enable this test'
  unless $ENV{TEST_CONN_PG};

has dbh => sub { DBI->connect(split m|[/]|, $ENV{TEST_CONN_PG}) };

my $config = do 't/config.pm';
my $pkg = __PACKAGE__;


sub startup {
  my $app = shift;
  $app->plugin('RoutesAuthDBI',
    #~ auth=>{current_user_fn=>'auth_user'},
    admin=>{prefix=>$config->{prefix}, trust=>$config->{trust}, role_admin=>$config->{role_admin},},
    oauth=>{
      providers => {
        google=>{
          key=>'foo-key.apps.googleusercontent.com',
          secret=>'foo-secret',
          foo=>'bar',
        },
      },
    },
    template=>$config,
  );
  
}

my $t = Test::Mojo->new($pkg);
$t->get_ok("/$config->{prefix}/sign/in/$config->{user2}/$config->{pass2}")->status_is(302)
  ->${ \$config->{location_is} }("/$config->{prefix}");

#~ $t->get_ok("/$config->{prefix}")->status_is(200)
  #~ ->content_like(qr/You are signed as/i);

$t->get_ok("/oauth/data")->status_is(200)
  ->json_is('/0/key'=>'foo-key.apps.googleusercontent.com', 'right api key')
  ->json_is('/0/foo'=>'bar', 'right option')
  ->json_hasnt('/0/secret', 'right no secret');

;


$t->get_ok("/$config->{trust}/oauth/conf")->status_is(200)
  ->content_like(qr'github')
  ;



done_testing();
