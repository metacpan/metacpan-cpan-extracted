use Mojo::Base -strict, -signatures;

use Test::More;
use Mojolicious::Lite;
use Mojo::Util 'secure_compare';
use Mojo::File;
use Test::Mojo;
use IO::Socket::INET;

# Home Dir
my $home = app->home->detect;
my $path = Mojo::File->new($home . '/migrations');

# User :
my $USERS = {yusrideb => 's3cr3t'};

plugin "Hakkefuin", {dir => 'migrations'};

app->secrets(['s3cr3t_m0j0l!c1oU5']);

get '/' => sub ($c) {
  $c->render(
    text => 'Welcome to Sample testing Mojolicious::Plugin::Hakkefuin');
};

get '/login-page' => sub ($c) {
  $c->render(text => 'login');
};

post '/login' => sub ($c) {

  # Query or POST parameters
  my $user = $c->param('user') || '';
  my $pass = $c->param('pass') || '';

  if ($USERS->{$user} && secure_compare $USERS->{$user}, $pass) {
    return $c->render(
      text => $c->mhf_signin($user) ? 'login success' : 'error login');
  }
  else {
    return $c->render(text => 'error user or pass');
  }
};

get '/csrf-reset' => sub ($c) {

  my $data_result = 'can\'t reset';
  my $result      = $c->mhf_has_auth();
  if ($result->{result} == 1) {
    $data_result = 'error reset';
    my $do_reset = $c->mhf_csrf_regen($c->stash('mhf.backend-id'));
    $data_result = 'success reset' if ($do_reset->[0]->{result} == 1);
  }
  $c->render(text => $data_result);
};

get '/page' => sub ($c) {
  $c->render(
    text => $c->mhf_has_auth()->{'code'} == 200 ? 'page' : 'Unauthenticated');
};

get '/stash' => sub ($c) {
  my $check_stash
    = $c->mhf_has_auth()->{code} == 200
    ? $c->stash->{'mhf.identify'}
    : 'fail stash login';
  $c->render(text => $check_stash);
};

post '/lock' => sub ($c) {
  my $result = $c->mhf_lock();
  my $text
    = $result->{result} == 1 ? 'locked'
    : $result->{result} == 2 ? 'already locked'
    :                          'lock failed';
  $c->render(text => $text);
};

post '/unlock' => sub ($c) {
  my $result = $c->mhf_unlock();
  my $text   = $result->{result} == 1 ? 'unlocked' : 'unlock failed';
  $c->render(text => $text);
};

post '/logout' => sub ($c) {
  my $check_auth = $c->mhf_has_auth();
  if ($check_auth->{'code'} == 200) {
    if ($c->mhf_signout($c->stash->{'mhf.identify'})->{code} == 200) {
      $c->render(text => 'logout success');
    }
  }

};

# Authentication Testing
my $probe = IO::Socket::INET->new(
  LocalAddr => '127.0.0.1',
  LocalPort => 0,
  Proto     => 'tcp',
  Listen    => 1
);
plan skip_all => 'listen not permitted in this environment' unless $probe;
$probe->close;

my $t = eval { Test::Mojo->new };
plan skip_all => "listen not permitted: $@" unless $t;
$t->ua->max_redirects(1);

# Main page
$t->get_ok('/')
  ->status_is(200)
  ->content_is('Welcome to Sample testing Mojolicious::Plugin::Hakkefuin');

# Login Page
$t->get_ok('/login-page')->status_is(200)->content_is('login', 'Login Page');

# Login Action is fails.
$t->post_ok('/login?user=yusrideb&pass=s3cr3t1')
  ->status_is(200)
  ->content_is('error user or pass', 'Fail Login');

# Login Action is Success
$t->post_ok('/login?user=yusrideb&pass=s3cr3t')
  ->status_is(200)
  ->content_is('login success', 'Success Login');

# Check Stash login
$t->get_ok('/stash')->status_is(200);

# CSRF Reset
$t->get_ok('/csrf-reset')
  ->status_is(200)
  ->content_is('success reset', 'CSRF reset success');

# Page with Authenticated
$t->get_ok('/page')->status_is(200)->content_is('page', 'Authenticated page');

# Lock session
$t->post_ok('/lock')->status_is(200)->content_is('locked', 'Session locked');

# Page should be blocked while locked
$t->get_ok('/page')
  ->status_is(200)
  ->content_is('Unauthenticated', 'Locked session is blocked');

# Unlock session
$t->post_ok('/unlock')
  ->status_is(200)
  ->content_is('unlocked', 'Session unlocked');

# Page with Authenticated after unlock
$t->get_ok('/page')->status_is(200)->content_is('page', 'Authenticated page');

# Logout
$t->post_ok('/logout')
  ->status_is(200)
  ->content_is('logout success', 'Logout Success');

# Page without Authenticated
$t->get_ok('/page')
  ->status_is(200)
  ->content_is('Unauthenticated', 'Unauthenticated page');

# Check stash login without Authenticated
$t->get_ok('/stash')
  ->status_is(200)
  ->content_is('fail stash login', 'stash is not found');

done_testing();

# Clear
$t->app->mhf_backend->drop_table if $t->app->can('mhf_backend');
$path->remove_tree               if -d $path;
