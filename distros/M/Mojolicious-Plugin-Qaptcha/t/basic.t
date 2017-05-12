use Test::More;
use Test::Mojo;

do "ex/qaptcha.pl";

my $t = Test::Mojo->new;
$t->get_ok('/inline')->status_is(200)
  ->content_like(qr'Hello Qaptcha!')
  ->content_like(qr'script');

$t->get_ok('/')->status_is(200)
  ->content_like(qr'Hello Qaptcha!')
  ->content_like(qr'script')
  ->content_like(qr'QapTcha - jQuery Plugin')
  ->content_like(qr'QapTcha CSS');

$t->get_ok('/images/bg_draggable_qaptcha.jpg')->status_is(200)
  ->content_type_is('image/jpeg');

$t->post_ok('/' => {DNT => 1} => form => {firstname => 'hans', lastname => 'test'})
  ->status_is(200)
  ->text_is('div#q_session' => '')
  ->text_is('div#f_processed' => 'form data not processed');

$t->post_ok('/qaptcha' => {DNT => 1} => form => {action => 'qaptcha', qaptcha_key => 'ABC'})
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
%= qaptcha_include;
</head>
<body>
%= content;
</body>
</html>

@@ index.html.ep
%= layout 'default';
'Hello Qaptcha!'
<div id="q_session">
%= c.session('qaptcha_key');
</div>
<div id="f_processed">
%= $form_processing;
</div>
<form method="post" action="">
  <fieldset>
    <label>First Name</label> <input name="firstname" type="text"><br>
    <label>Last Name</label> <input name="lastname" type="text">
    <div class="QapTcha"></div>
    <input name="submit" value="Submit form" style="margin-top:15px;" type="submit">
  </fieldset>
</form>

