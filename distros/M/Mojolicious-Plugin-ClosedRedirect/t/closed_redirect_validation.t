#!/usr/bin/env perl
use Mojolicious::Lite;
use Test::Mojo;
use Test::More;

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


# Check for local redirect parameter
get '/local' => sub {
  my $c = shift;
  my $v = $c->validation;

  $v->required('fwd')->closed_redirect('local');

  return $c->redirect_to($v->param('fwd')) unless $v->has_error;

  my $fail = $v->param('fwd') // 'no';
  $fail .= '-' . join(',', @{$v->error('fwd')});
  return $c->render(text => 'fail-' . $fail, status => 403);
} => 'local';


# Check for local redirect parameter
get '/all' => sub {
  my $c = shift;
  my $v = $c->validation;

  $v->required('fwd')->closed_redirect;

  return $c->redirect_to($v->param('fwd')) unless $v->has_error;

  my $fail = $v->param('fwd') // 'no';
  $fail .= '-' . join(',', @{$v->error('fwd')});
  return $c->render(text => 'fail-' . $fail, status => 403);
} => 'all';



my $t = Test::Mojo->new;

# Check signed
$t->get_ok('/signed?fwd=hallo')
  ->status_is(403)
  ->content_is('fail-no-closed_redirect,Redirect is invalid,signed');
is($fail, 'Fail: fwd:hallo - Redirect is invalid', 'Failed');
$fail = '';

my $url = '/mypath?crto=a4538583e3c0a534f3863050804c746a9bd92a2f';
is($url, app->close_redirect_to('/mypath'), 'Signing is valid');
$t->get_ok('/signed?fwd=' . $url)
  ->status_is(302)
  ->header_is('Location', '/mypath');
ok(!$fail, 'No fail');

# Change HMAC
my $url_shortened = substr($url, 1);
$t->get_ok('/signed?fwd=' . $url_shortened)
  ->status_is(403)
  ->content_is('fail-no-closed_redirect,Redirect is invalid,signed');
$fail = '';

$url_shortened = substr($url, 0, -1);
$t->get_ok('/signed?fwd=' . $url_shortened)
  ->status_is(403)
  ->content_is('fail-no-closed_redirect,Redirect is invalid,signed');
$fail = '';

# Only one fwd is fine!
$t->get_ok('/signed?fwd=/mypath?crto=a4538583e3c0a534f3863050804c746a9bd92a2f'.
             '&fwd=/mypath?crto=a4538583e3c0a534f3863050804c746a9bd92a2f')
  ->status_is(403)
  ->content_is('fail-no-closed_redirect,Redirect is defined multiple times,signed');
is($fail, 'Fail: fwd:/mypath?crto=a4538583e3c0a534f3863050804c746a9bd92a2f - Redirect is defined multiple times', 'Failed');
$fail = '';

my $surl = app->close_redirect_to('http://example.com/cool.php');
is($surl, 'http://example.com/cool.php?crto=9809dfc8b938498b70e3b0a290ba40109d914f71', 'Signed URL is fine');

$t->get_ok('/signed?fwd=' . $surl)
  ->status_is(302)
  ->header_is('Location', 'http://example.com/cool.php')
  ;
ok(!$fail, 'No fail');

# Fail
$t->get_ok('/signed?fwd=' . $surl . 'g')
  ->status_is(403)
  ->content_is('fail-no-closed_redirect,Redirect is invalid,signed')
  ;
is($fail, 'Fail: fwd:http://example.com/cool.php?crto=9809dfc8b938498b70e3b0a290ba40109d914f71g - Redirect is invalid', 'Hook');
$fail = '';



# Check local
$t->get_ok('/local?fwd=/tree')
  ->status_is(302)
  ->header_is('Location', '/tree');
ok(!$fail, 'No hook');

$t->get_ok('/local?fwd=' . app->url_for('signed')->query({ q => 123 }))
  ->status_is(302)
  ->header_is('Location', '/signed?q=123');
ok(!$fail, 'No hook');

$t->get_ok('/local?fwd=//tree')
  ->status_is(403)
  ->content_is('fail-no-closed_redirect,Redirect is invalid,local');
is($fail, 'Fail: fwd://tree - Redirect is invalid', 'Hook');
$fail = '';

# Signed URL is invalid, too
$t->get_ok('/local?fwd=' . $surl)
  ->status_is(403)
  ->content_is('fail-no-closed_redirect,Redirect is invalid,local');
is($fail, 'Fail: fwd:http://example.com/cool.php?crto=9809dfc8b938498b70e3b0a290ba40109d914f71 - Redirect is invalid', 'Hook');
$fail = '';

# Fail required
$t->get_ok('/local?fwd=')
  ->status_is(403)
  ->content_is('fail-no-required')
  ;
ok(!$fail, 'No hook');


# Check all
$t->get_ok('/all?fwd=hallo')
  ->status_is(403)
  ->content_is('fail-no-closed_redirect,Redirect is invalid');
is($fail, 'Fail: fwd:hallo - Redirect is invalid', 'Failed');
$fail = '';

$t->get_ok('/all?fwd=/mypath?crto=a4538583e3c0a534f3863050804c746a9bd92a2f')
  ->status_is(302)
  ->header_is('Location', '/mypath');
ok(!$fail, 'No fail');

$t->get_ok('/all?fwd=/tree')
  ->status_is(302)
  ->header_is('Location', '/tree');
ok(!$fail, 'No fail');

$t->get_ok('/all?fwd=//tree')
  ->status_is(403)
  ->content_is('fail-no-closed_redirect,Redirect is invalid');
is($fail, 'Fail: fwd://tree - Redirect is invalid', 'Hook');
$fail = '';

done_testing;
__END__

