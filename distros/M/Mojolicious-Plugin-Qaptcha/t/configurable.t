use Test::More;
use Test::Mojo;

use Mojo::Base -strict;

use Mojolicious::Lite;
use lib 'lib';

plugin 'Qaptcha', {
  inbuild_jquery          => 1,
  inbuild_jquery_ui       => 1,
  inbuild_jquery_ui_touch => 1,
  txtLock                 => "gesperrt",
  txtUnlock               => "entsperrt",
  disabledSubmit          => "true",
  autoRevert              => "false",
  autoSubmit              => "true",
  qaptcha_url             => '/entsperren',
};

any '/' => sub {
  my $self = shift;
  $self->stash(
    form_processing => sprintf("form data %s processed",
      $self->qaptcha_is_unlocked ? '' : 'not')
  );
  $self->render('index');
};

app->start();

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200)
  ->content_like(qr'gesperrt')
  ->content_like(qr'entsperrt')
  ->content_like(qr'disabledSubmit : true')
  ->content_like(qr'autoRevert : false')
  ->content_like(qr'autoSubmit : true');

$t->post_ok('/entsperren' => {DNT => 1} => form => {action => 'qaptcha', qaptcha_key => 'ABC'})
  ->status_is(200)
  ->json_is({error => 0});

  $t->post_ok('/' => {DNT => 1} => form => {firstname => 'hans', lastname => 'test'})
  ->status_is(200)
  ->text_is('div#q_session' => 'ABC')
  ->text_is('div#f_processed' => 'form data processed');

$t->post_ok('/' => {DNT => 1} => form => {firstname => 'hans', lastname => 'test'})
  ->status_is(200)
  ->text_is('div#q_session' => '')
  ->text_is('div#f_processed' => 'form data not processed');


done_testing();

__DATA__

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
<head>
%= qaptcha_include
</head>
<body>
%= content;
</body>
</html>

@@ index.html.ep
% layout 'default';
<div id="q_session">
<%= $c->session('qaptcha_key') %>
</div>
<div id="f_processed">
%= $form_processing;
</div>
<form method="post" action="">
  <fieldset>
    <label>First Name</label> <input name="firstname" type="text"><br>
    <label>Last Name</label> <input name="lastname" type="text">
    <input name="submit" value="Submit form" style="margin-top:15px;" type="submit">
    <br />
    <div class="QapTcha"></div>
  </fieldset>
</form>


