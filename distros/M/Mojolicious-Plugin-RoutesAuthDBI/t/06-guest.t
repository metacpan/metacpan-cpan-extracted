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
    guest=>{},
    template=>$config,
  );
  my $r = $app->routes;
  $r->get('/guest/new')->to( cb => sub {
    my $c = shift;
    
    $c->access->plugin->guest->store($c, {"foo"=>"♥"});
    
    $c->render(text=>'stored');
    
  } );
  
  $r->get('/guest/is')->to( cb => sub {
    my $c = shift;
    
    my $guest = $c->access->plugin->guest->current($c);
    
    return $c->reply->not_found
      unless $guest;
    
    $c->render(json=>$guest);
  });
  
  $r->get('/access')->over(access=>{guest=>1, auth=>'only'})->to( cb => sub {
    my $c = shift;
    
    $c->render(text=>'you have access');
    
  } );
}

my $t = Test::Mojo->new(PKG);

$t->get_ok("/guest/is")->status_is(404)
  #~ ->content_like(qr/Deny access at auth step/i)
  ;

$t->get_ok("/access")->status_is(401);

$t->get_ok("/$config->{prefix}/sign/in/$config->{admin_user}/$config->{admin_pass}")->status_is(302);

$t->get_ok("/access")->status_is(200);

$t->get_ok("/guest/new")->status_is(200)
  ->content_is('stored')
  #~ ->content_like(qr/Deny access at auth step/i)
  ;

$t->get_ok("/guest/is")->status_is(200)
  #~ ->content_is('stored')
  #~ ->content_like(qr/Deny access at auth step/i)
  ;

$t->get_ok("/access")->status_is(200);


done_testing();
