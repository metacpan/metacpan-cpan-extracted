use Mojo::Base -strict;

BEGIN {
  $ENV{PLACK_ENV}    = undef;
  $ENV{MOJO_MODE}    = 'development';
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Test::Mojo;
use Test::More;

plan skip_all => 'set TEST_ONLINE_mariadb to enable this test'
  unless $ENV{TEST_ONLINE_mariadb};

use Mojo::File 'curfile';
use IO::Socket::UNIX;
use Socket qw(SOCK_STREAM);
use lib curfile->sibling('lib')->to_string;

# Prefer unix socket to avoid network restrictions
my $sock = curfile->dirname->child('tmp', 'mojo-simple.sock');
$sock->dirname->make_path;
my $probe = IO::Socket::UNIX->new(
  Type   => SOCK_STREAM(),
  Local  => $sock->to_string,
  Listen => 1
);
plan skip_all => 'listen not permitted in this environment' unless $probe;
$probe->close;
unlink $sock->to_string if -S $sock->to_string;
local $ENV{MOJO_LISTEN} = 'http+unix:' . $sock->to_string
  unless $ENV{MOJO_LISTEN};

my $t = Test::Mojo->new('HakkefuinTestSimple');

my $home = $t->app->home->detect;
my $path = Mojo::File->new($home . '/migrations');

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
$t->get_ok('/stash')->status_is(200);    # CSRF Reset
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
$t->app->mhf_backend->empty_table;
$t->app->mhf_backend->drop_table;
$path->remove_tree;
unlink $sock->to_string if -S $sock->to_string;
my $tmpdir = $sock->dirname;
$tmpdir->remove_tree if -d $tmpdir && !$tmpdir->list->size;
