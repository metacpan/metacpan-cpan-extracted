use v5.26;
use warnings;

use Test2::V0;
use Capture::Tiny qw(capture_stderr);

use Authorization::AccessControl qw(acl);
use Mojo::Log;
use Mojolicious::Lite;

use experimental qw(signatures);

my $output;

plugin(
  'Authorization::AccessControl' => {
    log => undef
  }
);

app->authz->role->grant(User => 'list');

$output = capture_stderr {app->authz->request(User => 'list')->permitted};
is($output, '', 'Nothing in app log for granted');

$output = capture_stderr {app->authz->request(User => 'delete')->permitted};
is($output, '', 'Nothing in app log for denied');

plugin('Authorization::AccessControl');

$output = capture_stderr {acl->request->with_resource('User')->with_action('list')->permitted};
like($output, qr/\Q[Authorization::AccessControl] Granted: User => list()/, 'global acl - Granted in app log');

$output = capture_stderr {acl->request->with_resource('User')->with_action('delete')->permitted};
like($output, qr/\Q[Authorization::AccessControl] Denied: User => delete()/, 'global acl - Denied in app log');

$output = capture_stderr {app->authz->request(User => 'list')->permitted};
like($output, qr/\Q[Authorization::AccessControl] Granted: User => list()/, 'Granted in app log');

$output = capture_stderr {app->authz->request(User => 'delete')->permitted};
like($output, qr/\Q[Authorization::AccessControl] Denied: User => delete()/, 'Denied in app log');

app->log->level('fatal')
  ; # TODO: this is needed because we just stack a new set of hooks onto the global acl every time we load the plugin. Realistically, reloading the plugin is not a big issue in the real world, but we should fix this someday
my $log = Mojo::Log->new(path => '/tmp/auth.log');
plugin(
  'Authorization::AccessControl' => {
    log => $log
  }
);

app->authz->request(User => 'list')->permitted;
$output = `tail -n 1 /tmp/auth.log`;
like($output, qr/\Q[Authorization::AccessControl] Granted: User => list()/, 'Granted in log file');

app->authz->request(User => 'delete')->permitted;
$output = `tail -n 1 /tmp/auth.log`;
like($output, qr/\Q[Authorization::AccessControl] Denied: User => delete()/, 'Denied in log file');

done_testing;
