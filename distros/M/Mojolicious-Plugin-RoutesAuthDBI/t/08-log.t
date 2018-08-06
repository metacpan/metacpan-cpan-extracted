use Mojo::Base 'Mojolicious';
use Test::More;
use Test::Mojo;
use DBI;

use constant PKG => __PACKAGE__;

plan skip_all => 'set env TEST_CONN_PG="DBI:Pg:dbname=<db>/<pg_user>/<passwd>" to enable this test'
  unless $ENV{TEST_CONN_PG};

has dbh => sub { DBI->connect(split m|[/]|, $ENV{TEST_CONN_PG}) };

my $config = do 't/config.pm';


sub startup {
  my $app = shift;
  $app->plugin('RoutesAuthDBI',
    admin=>{prefix=>$config->{prefix}, trust=>$config->{trust}, role_admin=>$config->{role_admin},},
    log=>{},
    template=>$config,
  );
  my $r = $app->routes;
  $r->get('/')->to( cb => sub {
    my $c = shift;
    
    $c->render(text=>'see LOG');
    
  } );
}

my $t = Test::Mojo->new(PKG);

$t->get_ok("/$config->{prefix}/sign/in/$config->{admin_user}/$config->{admin_pass}")->status_is(302);

$t->get_ok("/")->status_is(200);
$t->get_ok("/foo")->status_is(404);


done_testing();
