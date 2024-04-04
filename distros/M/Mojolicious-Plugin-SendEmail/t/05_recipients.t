use v5.26;
use warnings;

use Test2::V0;
use Test2::Tools::Warnings qw(warns);
use Mojolicious::Lite;
use List::MoreUtils qw(arrayify);

use experimental qw(signatures);

my $email;

plugin 'SendEmail' => {from => 'app@tyrrminal.dev'};

$email = app->create_email(to => 'mark@tyrrminal.dev',);
like($email->as_string, qr/To: mark\@tyrrminal.dev\r$/m, 'default resolution of address');

$email = app->create_email(to => '"Mark Tyrrell" <mark@tyrrminal.dev>',);
like($email->as_string, qr/To: "Mark Tyrrell" <mark\@tyrrminal.dev>\r$/m, 'default resolution of name + address');

like(warning {app->create_email(to => 'mark')}, qr/^Argument contains empty address/, "default resolution of non-address");

my $recipient_map = {
  default => 'help@tyrrminal.dev',
  mark    => 'mark@tyrrminal.dev',
  tests   => ['test1@tyrrminal.dev', 'test2@tyrrminal.dev'],
  admins  => ['admin@tyrrminal.dev', 't@tyrrminal.dev'],
  super   => ['mark',                'admins'],
};

my $resolver = sub ($add) {
  if (defined($add)) {
    return [arrayify(map {__SUB__->($_)} $add->@*)] if (ref($add) eq 'ARRAY');
    return $add                                     if ($add =~ /@/);
    return __SUB__->($recipient_map->{$add} // $recipient_map->{default}) unless (ref($add));
  }
  return ();
};

plugin 'SendEmail' => {
  from               => 'app@tyrrminal.dev',
  recipient_resolver => $resolver,
};

$email = app->create_email(to => 'mark@tyrrminal.dev',);
like($email->as_string, qr/To: mark\@tyrrminal.dev\r$/m, 'custom resolution of address');

$email = app->create_email(to => 'mark',);
like($email->as_string, qr/To: mark\@tyrrminal.dev\r$/m, 'custom resolution of non-address');

$email = app->create_email(
  to => 'mark@tyrrminal.dev',
  cc => 'admins'
);
like($email->as_string, qr/Cc: admin\@tyrrminal.dev, t\@tyrrminal.dev\r$/m, 'custom resolution of group');

$email = app->create_email(
  to => 'mark@tyrrminal.dev',
  cc => 'super'
);
like(
  $email->as_string,
  qr/Cc: mark\@tyrrminal.dev, admin\@tyrrminal.dev, t\@tyrrminal.dev\r$/m,
  'recursive custom resolution of group'
);

$email = app->create_email(to => 'unknown_group',);
like($email->as_string, qr/To: help\@tyrrminal.dev\r$/m, 'custom resolution of unknown to default');

done_testing;
