#!/usr/bin/env perl
use Mojolicious::Lite;
use Test::Mojo;
use Test::More;
use Mojo::Util qw/url_escape/;

app->secrets(['abcdefghijklmnopqrstuvwxyz']);

plugin 'ClosedRedirect';

my $fail;
app->hook(
  on_open_redirect_attack => sub {
    my ($field, $url, $msg) = @_;
    $msg //= '';
    $fail = "Fail: $field:$url - $msg";
  }
);

# Check for signed redirect parameter
get '/signed' => sub {
  my $c = shift;
  my $v = $c->validation;

  $v->required('fwd')->closed_redirect('signed');

  return $c->redirect_to($v->param('fwd')) unless $v->has_error;

  my $fail = $v->param('fwd') // 'no';
  $fail .= '-' . join(',', @{$v->error('fwd')});
  return $c->render(text => 'fail-' . $fail, status => 403);
} => 'signed';

# Named route
get '/mypath' => sub {
  return shift->render(text => 'test');
} => 'myname';

# Check for signed redirect parameter
get '/my/:user/path' => sub {
  return shift->render(text => 'fun');
} => 'myname2';


my $t = Test::Mojo->new;

# Check sign helper
$t->get_ok('/signed?fwd=' . app->close_redirect_to('http://example.com/'))
  ->status_is(302)
  ->header_is('Location', 'http://example.com/');
ok(!$fail, 'No fail');

my $app = $t->app;
my $c = $app->build_controller;

my $fine = '/my/peter/path' . '?crto=e10b3e94fbf66c38444ade5dde9447ae369d9baf';
is($app->close_redirect_to('myname2', user => 'peter'), $fine, 'signed url');
is($c->close_redirect_to('myname2', user => 'peter'), $fine, 'signed url');

# Check signed with param
my $sign = app->close_redirect_to('/mypath?test=hmm');
like($sign, qr!/mypath\?.*?crto=3da434e37b38bef41132aacf82d5b91c7cedbbc4!, 'Signed with parameter');

is($app->close_redirect_to($app->url_for('myname')->query({ test => 'hmm' })), $sign, 'signed url');
is($c->close_redirect_to($c->url_for('myname')->query({ test => 'hmm' })), $sign, 'signed url');

$t->get_ok('/signed?para=hui&fwd=' . url_escape($sign))
  ->status_is(302)
  ->header_is('Location', '/mypath?test=hmm');

$sign = substr($sign, 0, -1);
like ($sign, qr!crto=3da434!, 'is still signed');
$t->get_ok('/signed?para=hui&fwd=' . url_escape($sign))
  ->status_is(403)
  ->content_is('fail-no-closed_redirect,Redirect is invalid,signed');


# Check with hash
my $base = 'http://example.com/?name=test&crto=8a986b12b3d7c6ae668238d41ec08907076d4d04#age';
my $pure = 'http://example.com/?name=test#age';
$fine = 'http://example.com/?name=test&crto=8a986b12b3d7c6ae668238d41ec08907076d4d04#age';
is($app->close_redirect_to($base), $fine, 'signed url');
is($c->close_redirect_to($base), $fine, 'signed url');

$t->get_ok('/signed?fwd=' . url_escape($base) . '#haha')
  ->status_is(302)
  ->header_is('Location', 'http://example.com/?name=test#age');


done_testing;
__END__

