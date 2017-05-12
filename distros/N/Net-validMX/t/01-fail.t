#!perl -T

use Test::More tests => 11;

use Net::validMX;

sub test {
  my ($email) = @_;
  my ($rv, $reason);

  ($rv, $reason) = &Net::validMX::check_valid_mx($email);
  print &Net::validMX::get_output_result($email, $rv, $reason);
 
  return $rv;
}

is( test('postmaster@[127.0.0.1]'), 0 , 'Test for Explicit IP instead of domain name');

is( test('test@test4.peregrinehw.com'), 0 , 'Test for a host that is configured with an MX of . & priority 10 which will be considered a pass due eNom.com (name-services.com) false positives - Should Fail if it\'s the only MX');

is( test('nofrom@www'), 0, 'Test for non-FQDN');

is( test('test@test3.peregrinehw.com'), 0, 'Test for a host that is configured with an MX of . & priority 0 which is an \'I don\'t do email\' Notification - Should Fail');

is( test('zqy152214@liyuanculture.com'), 0, 'Test for incorrect DNS');

is( test('formation2005@carmail.com'), 0, 'Test for incorrect DNS');

is( test('test@geg.com'), 0, 'Test for privatized IP range use only');

is( test('test@test5.peregrinehw.com'), 0, 'Test for privatized IP range use only');

is ( test('test@tennesseen.com'), 0, 'Test for non-resolvable MX records');

is ( test('zacaris@muska.com'), 0, 'Resolves to an implicit cname that is chained to a cname - fails but not certain I should allow this or not');

is( test('test@test2.peregrinehw.com'), 0, 'Test for use of crazy things like 192.168.0.1. as the host name in DNS - Should FAIL EVEN if $allow_ip_address_as_mx = 1 because they are privatized not because of the name');
