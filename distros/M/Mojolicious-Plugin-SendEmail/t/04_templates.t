use v5.26;
use warnings;

use Test2::V0;
use Mojolicious::Lite;
use Mojo::Log;

#suppress mojo logging so we don't see 'Rendering template ...' when testing
app->log(Mojo::Log->new(path => '/dev/null'));

my $email;

$ENV{MOJO_HOME} = "./t";

plugin 'SendEmail' => {from => 'mark@tyrrminal.dev'};

$email = app->create_email(
  to       => 'testers@tyrrminal.dev',
  subject  => 'Template Test',
  template => 'user/static'
);

my $static = <<"END";
<!DOCTYPE html>\r
\r
<html>\r
<body>\r
This is a simple static message\r
\r
</body>\r
</html>\r
END

is($email->email->body, $static, 'check email template body');
like($email->as_string, qr/^Content-Type: text\/html; charset=utf-8\r$/m, 'check html content type autodetection with template');

$email = app->create_email(
  to       => 'mark@tyrrminal.dev',
  template => 'user/register',
  params   => {
    username => 'tyrrminal'
  }
);

my $register = <<"END";
<!DOCTYPE html>\r
\r
<html>\r
<body>\r
Welcome to tyrrminal.dev, tyrrminal\r
\r
</body>\r
</html>\r
END

is($email->email->body, $register, 'check email template body (register)');
like(
  $email->as_string,
  qr/^Content-Type: text\/html; charset=utf-8\r$/m,
  'check html content type autodetection with template (register)'
);

my $simple = <<"END";
This is a text template with great interpolation\r
\r
and multiple lines!\r
\r
Bye mark\r
END

$email = app->create_email(
  to       => 'mark@tyrrminal.dev',
  template => 'simple',
  params   => {
    variable => 'great',
    name     => 'mark'
  }
);

is($email->email->body, $simple, 'check email template body (simple)');
like(
  $email->as_string,
  qr/^Content-Type: text\/plain; charset=utf-8\r$/m,
  'check text content type autodetection with template (simple)'
);

done_testing;
