#!perl -T

use Test::More tests => 3;

use Net::validMX qw(check_email_and_mx);

sub test {
  my ($email) = @_;
  my ($rv, $reason);

  ($rv, $reason) = &Net::validMX::check_email_and_mx($email);
  print &Net::validMX::get_output_result($email, $rv, $reason);

  return $rv;
}

is( &test('kevin.mcgrail@thoughtworthy.com'), 1, 'Test for valid email format');
is( &test('kevin.mcgrail@aol'), 1, 'Test for valid email format with sanitize');
is( &test('kevin.mcgrail @ ThoughtWorthy .com'), 1, 'Test for valid email with spaces');
