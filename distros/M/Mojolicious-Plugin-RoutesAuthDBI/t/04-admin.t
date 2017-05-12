use Mojo::Base 'Mojolicious';
use Test::More;
use Test::Mojo;
use DBI;

plan skip_all => 'set env TEST_CONN_PG="DBI:Pg:dbname=<db>/<pg_user>/<passwd>" to enable this test'
  unless $ENV{TEST_CONN_PG};

has dbh => sub { DBI->connect(split m|[/]|, $ENV{TEST_CONN_PG}) };

my $config = do 't/config.pm';

sub startup {
  my $app = shift;
  $app->plugin('RoutesAuthDBI',
    auth=>{current_user_fn=>'auth_user'},
    admin=>{prefix=>$config->{prefix}, trust=>$config->{trust}, role_admin=>$config->{role_admin},},
    template=>$config,
  );
}

my $t = Test::Mojo->new(__PACKAGE__);

subtest 'routes' => sub {
  #~ my $stdout;
  #~ local *STDOUT;
  #~ open(STDOUT, ">", \$stdout);
  #~ $t->app->commands->run('routes');
  my $stdout = $config->{app_routes}($t);
  warn $stdout;
  like $stdout, qr/\/$config->{prefix}\/$config->{trust}\/$config->{role_admin}\/new\/:login\/:pass/, 'routes';
  like $stdout, qr/signin stash/, 'sign in route';
};


$t->get_ok("/$config->{prefix}")->status_is(401)
  ->content_like(qr/Please sign in/i);

$t->get_ok("/$config->{prefix}/$config->{trust}/$config->{role_admin}/new/$config->{admin_user}/$config->{admin_pass}")->status_is(200)
  ->content_like(qr/Success sign up new trust-admin-user/i);
  #~ ->content_like(qr/$config->{role_admin}-000/i);

$t->get_ok("/$config->{prefix}/sign/in/$config->{admin_user}/$config->{admin_pass}")->status_is(302)
  ->${ \$config->{location_is} }("/$config->{prefix}");

$t->get_ok("/$config->{prefix}")->status_is(200)
  ->content_like(qr/You are signed as/i);

$t->get_ok("/$config->{prefix}/users")->status_is(200)
  ->content_like(qr/Profiles\(1\)/i);

$t->get_ok("/$config->{prefix}/user/new/$config->{user1}/$config->{pass1}")->status_is(200)
  ->content_like(qr/Success sign up new profile/i);

$t->get_ok("/$config->{prefix}/user/new?login=$config->{user2}&pass=$config->{pass2}")->status_is(200)
  ->content_like(qr/Success sign up new profile/i);

$t->get_ok("/$config->{prefix}/users")->status_is(200)
  ->content_like(qr/Profiles\(3\)/i);

$t->get_ok("/$config->{prefix}/users/$config->{role_admin}")->status_is(200)
  ->content_like(qr/Profile\/users\(1\) by role \[$config->{role_admin}\]/i);

$t->get_ok("/$config->{prefix}/role/new/$config->{role}")->status_is(200)
  ->content_like(qr/Success created role/i);

$t->get_ok("/$config->{prefix}/role/user/$config->{role}/$config->{user1}")->status_is(200)
  ->content_like(qr/Success assign ROLE\[$config->{role}\] -> USER \[bless/i);

$t->get_ok("/$config->{prefix}/users/$config->{role}")->status_is(200)
  ->content_like(qr/Profile\/users\(1\) by role \[$config->{role}\]/i);

$t->get_ok("/$config->{prefix}/roles/$config->{user1}")->status_is(200)
  ->content_like(qr/List of profile\/login roles \(1\)/i);

$t->get_ok("/$config->{prefix}/roles")->status_is(200)
  ->content_like(qr/ROLES\(2\)/i);

$t->get_ok("/$config->{prefix}/role/dsbl/$config->{role}")->status_is(200)
  ->content_like(qr/Success disable role/i);

$t->get_ok("/$config->{prefix}/role/enbl/$config->{role}")->status_is(200)
  ->content_like(qr/Success enable role/i);

$t->get_ok("/$config->{prefix}/role/del/$config->{role}/$config->{user1}")->status_is(200)
  ->content_like(qr/Success delete ref ROLE\[$config->{role}\] -> USER\[bless/i);

$t->get_ok("/$config->{prefix}/users/$config->{role}")->status_is(200)
  ->content_like(qr/Profile\/users\(0\) by role \[$config->{role}\]/i);

$t->get_ok("/$config->{prefix}/roles/$config->{user1}")->status_is(200)
  ->content_like(qr/List of profile\/login roles \(0\)/i);

$t->get_ok("/$config->{prefix}/namespaces")->status_is(200)
  ->content_like(qr/Namespaces \(1\)/i);

$t->get_ok("/$config->{prefix}/controllers")->status_is(200)
  ->content_like(qr/controllers \(1\)/i);

$t->get_ok("/$config->{prefix}/controller/new/undef/Test1?descr=any test controller")->status_is(200)
  ->content_like(qr/Success create new controller/i);

$t->get_ok("/$config->{prefix}/controllers")->status_is(200)
  ->content_like(qr/controllers \(2\)/i);

$t->get_ok("/$config->{prefix}/controller/undef/Test1")->status_is(200)
  ->content_like(qr/"controller" => "Test1",/i);

$t->get_ok("/$config->{prefix}/route/new")->status_is(200)
  ->content_like(qr/Namespaces \(1\)/i);

$t->get_ok("/$config->{prefix}/route/new/undef")->status_is(200)
  ->content_like(qr/"namespace" => undef/i);

$t->get_ok("/$config->{prefix}/route/new/undef/Test1")->status_is(200)
  ->content_like(qr/"controller" => "Test1"/i);

$t->get_ok("/$config->{prefix}/route/new/undef/Test1/test1")->status_is(200)
  ->content_like(qr/"action" => "test1"/i);

$t->get_ok("/$config->{prefix}/route/new/undef/Test1/test1?request=GET FOO /test1&name=Test1->test1&descr=controller none namespace")->status_is(200)
  ->content_like(qr/Success done save!/i);

$t->get_ok("/$config->{prefix}/routes")->status_is(200)
  ->content_like(qr/ROUTES \(1\)/i);

$t->get_ok("/$config->{prefix}/route/new/undef/Test1/undef?request=GET FOO /test2&to=->test2&name=Test1 on test2&descr=route ref controll")->status_is(200)
  ->content_like(qr/Success done save!/i);

$t->get_ok("/$config->{prefix}/routes")->status_is(200)
  ->content_like(qr/ROUTES \(2\)/i);

$t->get_ok("/$config->{prefix}/route/new/undef/undef/undef?request=POST /test3&to=Test1->test3&name=Test1 on test3&descr=route none ref controll/action")->status_is(200)
  ->content_like(qr/"request" => "POST \/test3"/i);

$t->get_ok("/$config->{prefix}/routes")->status_is(200)
  ->content_like(qr/ROUTES \(3\)/i);

$t->get_ok("/$config->{prefix}/role/controller/$config->{role_admin}/undef/Test1")->status_is(200)
  ->content_like(qr/Success assign access/i);

done_testing();
