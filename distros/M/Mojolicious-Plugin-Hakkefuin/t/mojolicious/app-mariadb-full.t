use Mojo::Base -strict;

BEGIN {
  $ENV{PLACK_ENV}    = undef;
  $ENV{MOJO_MODE}    = 'development';
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Test::More;
use Test::Mojo;
use IO::Socket::INET;
use Mojo::File 'curfile';
use lib curfile->sibling('lib')->to_string;

plan skip_all => 'set TEST_ONLINE_mariadb to enable this test'
  unless $ENV{TEST_ONLINE_mariadb};

my $probe = IO::Socket::INET->new(
  LocalAddr => '127.0.0.1',
  LocalPort => 0,
  Proto     => 'tcp',
  Listen    => 1
);
plan skip_all => 'listen not permitted in this environment' unless $probe;
$probe->close;

my $t = eval { Test::Mojo->new('HakkefuinTestMariaDb') };
plan skip_all => "listen not permitted: $@" unless $t;
$t->ua->max_redirects(1);

my $migrations = $t->app->home->child('migrations', 'full-mariadb');

# Main page
$t->get_ok('/')
  ->status_is(200)
  ->content_is('Welcome to Sample testing Mojolicious::Plugin::Hakkefuin');

# Login Page
$t->get_ok('/login-page')->status_is(200)->content_is('login', 'Login Page');

# Login Action is fails.
$t->post_ok('/login?user=yusrideb&pass=s3cr3t')
  ->status_is(200)
  ->content_is('error user or pass', 'Fail Login');

# Login Action is Success
$t->post_ok('/login?user=yusrideb&pass=s3cr3t1')
  ->status_is(200)
  ->content_is('login success', 'Success Login');

# Check Stash login
$t->get_ok('/stash')->status_is(200);
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

# Auth Update
$t->get_ok('/auth-update')
  ->status_is(200)
  ->content_is('success update auth', 'success update auth');

# Page with Authenticated
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

# Login Action with second username
$t->post_ok('/login?user=another&pass=s3cr3t2')
  ->status_is(200)
  ->content_is('login success', 'Success Login');

# Page with Authenticated
$t->get_ok('/page')->status_is(200)->content_is('page', 'Authenticated page');

# Logout
$t->post_ok('/logout')
  ->status_is(200)
  ->content_is('logout success', 'Logout Success');

done_testing();

# Clear
$t->app->mhf_backend->drop_table;
$migrations->remove_tree if -d $migrations;
$migrations->dirname->remove_tree
  if -d $migrations->dirname && !$migrations->dirname->list->size;
