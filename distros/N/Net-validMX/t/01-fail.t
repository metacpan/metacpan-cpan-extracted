#!/usr/bin/perl -T

use lib 'lib';

use Test::More;
plan tests => 12;

use Net::validMX;

sub test {
  my ($email) = @_;
  my ($rv, $reason);

  ($rv, $reason) = Net::validMX::check_valid_mx($email);
  print Net::validMX::get_output_result($email, $rv, $reason);
 
  return $rv;
}

sub test_email_validity {
  my ($email) = @_;
  my ($rv, $reason);

  $rv = Net::validMX::check_email_validity($email);
  print Net::validMX::get_output_result($email, $rv, '');

  return $rv;
}

is( test('postmaster@[127.0.0.1]'), 0 , 'Test for Explicit IP instead of domain name');

is( test('test@test4.peregrinehw.com'), 0 , 'Test for a host that is configured with an MX of . & priority 10 which will be considered a pass due eNom.com (name-services.com) false positives - Should Fail if it\'s the only MX');

is( test('nofrom@www'), 0, 'Test for non-FQDN');

is( test('test@test3.peregrinehw.com'), 0, 'Test for a host that is configured with an MX of . & priority 0 which is an \'I don\'t do email\' Notification - Should Fail');

#REMOVED BECAUSE IT RELIES ON BAD CONFIGURATION TO PERSIST ON A DOMAIN OUTSIDE OUR DEVELOPMENT CONTROL
#is( test('zqy152214@liyuanculture.com'), 0, 'Test for incorrect DNS');

#REMOVED BECAUSE IT RELIES ON BAD CONFIGURATION TO PERSIST ON A DOMAIN OUTSIDE OUR DEVELOPMENT CONTROL
#is( test('formation2005@carmail.com'), 0, 'Test for incorrect DNS');

#REMOVED BECAUSE IT RELIES ON BAD CONFIGURATION TO PERSIST ON A DOMAIN OUTSIDE OUR DEVELOPMENT CONTROL
#is( test('test@geg.com'), 0, 'Test for privatized IP range use only');

is( test('test@test5.peregrinehw.com'), 0, 'Test for privatized IP range use only');

#REMOVED BECAUSE IT RELIES ON BAD CONFIGURATION TO PERSIST ON A DOMAIN OUTSIDE OUR DEVELOPMENT CONTROL
#is ( test('test@tennesseen.com'), 0, 'Test for non-resolvable MX records');

is ( test('test@test8.peregrinehw.com'), 0, 'Test for non-resolvable MX records');

#REMOVED BECAUSE IT RELIES ON BAD CONFIGURATION TO PERSIST ON A DOMAIN OUTSIDE OUR DEVELOPMENT CONTROL
#is ( test('zacaris@muska.com'), 0, 'Resolves to an implicit cname that is chained to a cname - fails but not certain I should allow this or not');

is ( test('test@test9.peregrinehw.com'), 0, 'Resolves to an explicit cname that is chained to a cname - fails but not certain I should allow this or not');

is ( test('test@test10.peregrinehw.com'), 0, 'Resolves to an implicit cname that is chained to a cname - fails but not certain I should allow this or not');

is ( test('test@test17.peregrinehw.com'), 0, 'Resolves to a link-local ipv6 address - fails because it resolves to a private ip');

is( test('test@test2.peregrinehw.com'), 0, 'Test for use of crazy things like 192.168.0.1. as the host name in DNS - Should FAIL EVEN if $allow_ip_address_as_mx = 1 because they are privatized not because of the name');

is( test_email_validity(''), 0, 'Blank email addresses should fail');

is( test_email_validity('foo\"@bar.org'), 0, 'Email addresses with double quotes should fail');
