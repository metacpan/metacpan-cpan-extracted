use Mojo::Base 'Mojolicious';
use Test::More;
use Test::Mojo;
use DBI;
use lib 't';

plan skip_all => 'set env TEST_CONN_PG="DBI:Pg:dbname=<db>/<pg_user>/<passwd>" to enable this test'
  unless $ENV{TEST_CONN_PG};

has dbh => sub { DBI->connect(split m|[/]|, $ENV{TEST_CONN_PG})};

my $config = do 't/config.pm';

sub startup {
  my $app = shift;
  $app->plugin('RoutesAuthDBI',
    auth=>{current_user_fn=>'auth_user'},
    admin=>{prefix=>$config->{prefix}, trust=>$config->{trust}, role_admin=>$config->{role_admin},},
    template=>$config,
  );
  my $r = $app->routes;
  push @{ $r->namespaces }, 'Test';
  
  $r->route('/noauth')->over(access=>{auth=>0,})
    ->to('install#manual', namespace=>$config->{namespace});
  
  $r->route('/auth-only')->over(access=>{auth=>'only'})
    ->to('install#manual', namespace=>$config->{namespace});
  
  $r->get('/authenticated')->over(authenticated => 1)
    ->to('install#manual', namespace=>$config->{namespace});
  
  $r->route('/test1/:action')->over(access=>{auth=>1})->to(controller=>'Test1',);
  
  $r->route('/callback')->over(access=>{role=>$config->{role_admin}})
    ->to(cb=>sub {shift->render(format=>'txt', text=>'Admin role have access')},);
  
  $r->route('/auth/cookie')->to( cb => sub {
    my $c = shift;
    #~ cookie($c);
    my $json = $c->req->json;
    return $c->render(json=>{cookie=>$c->access->auth_cookie($c)})
      unless $json && $json->{cookie};
    
    return $c->render(json=>{profile=>{ %{$c->access->auth_cookie($c, $json->{cookie})} } });
    
  } );
}

my $t = Test::Mojo->new(__PACKAGE__);

#~ subtest 'foo' => sub {
  #~ my $routes = $config->{app_routes}($t);
  #~ warn $routes;
#~ };

$t->get_ok("/noauth")->status_is(200)
  ->content_like(qr/Welcome  Mojolicious::Plugin::RoutesAuthDBI/i);

$t->get_ok("/auth-only")->status_is(401)
  ->content_like(qr/Please sign in/i);

$t->get_ok("/authenticated")->status_is(404);
  #~ ->content_like(qr/Please sign in/i);

$t->get_ok("/$config->{prefix}/sign/in/$config->{admin_user}/$config->{admin_pass}")->status_is(302)
  ->${ \$config->{location_is} }("/$config->{prefix}");

$t->get_ok("/$config->{prefix}")->status_is(200)
  ->content_like(qr/You are signed as/i);

$t->get_ok("/auth-only")->status_is(200)
  ->content_like(qr/Welcome  Mojolicious::Plugin::RoutesAuthDBI/i);

$t->get_ok("/authenticated")->status_is(200)
  ->content_like(qr/Welcome  Mojolicious::Plugin::RoutesAuthDBI/i);

$t->get_ok("/test1/test1")->status_is(200)
  ->content_like(qr/test1\.+ok/i);

$t->get_ok("/test1")->status_is(200)
  ->content_like(qr/test1\.+ok/i);

$t->get_ok("/callback")->status_is(200)
  ->content_like(qr/Admin role have access/i);

$t->get_ok("/auth/cookie")->status_is(200)
  ->json_like('/cookie' => qr'^(?:\w+)--(?:[^\-]+)$')
  ;

my $cookie = $t->tx->res->json->{cookie};
#~ $t->app->log->debug($cookie);

$t->get_ok("/logout")->status_is(302)
  ;

$t->get_ok("/$config->{prefix}")->status_is(401)
  ->content_like(qr/Please sign in/i);

my $cookie0= $t->tx->res->cookie($t->app->sessions->cookie_name);
isnt $cookie =~ s/--([^\-]+)$//r, $cookie0 && $cookie0->value =~ s/--([^\-]+)$//r, 'no auth cookie'; 

$t->post_ok('/auth/cookie' => json => {cookie => $cookie}) #
  ->status_is(200);

#~ $t->app->log->fatal($t->app->dumper($t->tx->res->headers));

$t->json_like('/profile/auth_cookie' => qr'^(?:\w+)--(?:[^\-]+)$');

my $cookie2 = $t->tx->res->cookie($t->app->sessions->cookie_name);
my $cookie3 = $t->tx->res->json->{profile}{auth_cookie};

is $cookie =~ s/--([^\-]+)$//r, $cookie2 && $cookie2->value =~ s/--([^\-]+)$//r, 'auth cookie'; #$t->tx->res->json->{cookie}

is $cookie =~ s/--([^\-]+)$//r, $cookie3 =~ s/--([^\-]+)$//r, 'profile cookie'; 

#~ is '123', $t->app->dumper($t->tx->res->json->{profile}), 'profile';

$t->get_ok("/$config->{prefix}")->status_is(200)
  ->content_like(qr/You are signed as/i);


done_testing();
