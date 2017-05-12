#!/usr/bin/env perl
use Mojo::Base -strict;

use Mojolicious::Lite;
use lib 'lib';

plugin 'Qaptcha', {
  inbuild_jquery          => 1,
  inbuild_jquery_ui       => 1,
  inbuild_jquery_ui_touch => 1,
};

get '/inline' => sub {
  my $self = shift;
  $self->render(inline => 'Hello Qaptcha! <%= qaptcha_include %>');
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
'Hello Qaptcha!'
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

