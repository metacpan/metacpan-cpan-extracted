use v5.26;
use warnings;

use Test2::V0;
use Test2::Tools::Exception qw(dies);

use Mojolicious::Lite;

use experimental qw(signatures);

my $email;

plugin 'SendEmail';

like(
  dies {app->create_email(to => 'recipient@tyrrminal.dev')},
  qr/^Can't send email: no from address given/,
  'check that dies with no "from"'
);

like(
  dies {app->email_transport([])},
  qr/email_transport argument must be an Email::Sender::Transport instance/,
  'die if email_transport arg not a transport obj'
);

plugin 'SendEmail' => {
  from => 'mark@tyrrminal.dev',
  host => 'mail.test.com',
  port => 1025,
};

$email = app->create_email(to => 'recipient@tyrrminal.dev');

like($email->as_string, qr/From: mark\@tyrrminal.dev\r$/m, 'check "from" from config');

$email = app->create_email(
  from => 'override@tyrrminal.dev',
  to   => 'recipient@tyrrminal.dev',
);

like($email->as_string, qr/^From: override\@tyrrminal.dev\r$/m, 'test email from override');

like(app->email_transport->host, 'mail.test.com', 'check transport host');
like(app->email_transport->port, 1025,            'check transport port');

like(
  dies {plugin 'SendEmail' => {sasl_username => 'username'}},
  qr/sasl_username but no sasl_password/,
  'test username with no password'
);

done_testing;
