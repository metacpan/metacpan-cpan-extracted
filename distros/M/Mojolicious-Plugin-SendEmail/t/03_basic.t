use v5.26;
use warnings;

use Test2::V0;
use Mojolicious::Lite;

use experimental qw(signatures);

plugin 'SendEmail' => {from => 'test@tyrrminal.dev',};

my $email = app->create_email(
  to      => 'recipient@tyrrminal.dev',
  subject => 'This is a test email',
  body    => 'This is a test email',
);

is($email->email->body, q/This is a test email/, 'test email body');
like($email->as_string, qr/^From: test\@tyrrminal.dev\r$/m,                'test email subject');
like($email->as_string, qr/^To: recipient\@tyrrminal.dev\r$/m,             'test email subject');
like($email->as_string, qr/^Subject: This is a test email\r$/m,            'test email subject');
like($email->as_string, qr/^Content-Type: text\/plain; charset=utf-8\r$/m, 'test text content type');

$email = app->create_email(
  to   => 'newb@tyrrminal.dev',
  body => '<!DOCTYPE html><html><body>This is a test email</body></html>',
);

like($email->as_string, qr/^Content-Type: text\/html; charset=utf-8\r$/m, 'test html content type autodetection');

$email = app->create_email(
  to   => 'newb@tyrrminal.dev',
  body => '<!DOCTYPE html><html><body>This is a test email</body></html>',
  html => 0,
);

like($email->as_string, qr/^Content-Type: text\/plain; charset=utf-8\r$/m, 'test text content type manual');

$email = app->create_email(
  to   => 'newb@tyrrminal.dev',
  body => 'This is a test email',
  html => 1,
);

like($email->as_string, qr/^Content-Type: text\/html; charset=utf-8\r$/m, 'test html content type manual');

done_testing;
