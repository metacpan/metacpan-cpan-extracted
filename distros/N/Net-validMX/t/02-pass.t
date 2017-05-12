#!perl -T

use Test::More tests => 8;

use Net::validMX;

sub test {
  my ($email) = @_;
  my ($rv, $reason);

  ($rv, $reason) = &Net::validMX::check_valid_mx($email);
  print &Net::validMX::get_output_result($email, $rv, $reason);
 
  return $rv;
}

is( test('kevin.mcgrail@thoughtworthy.com'), 1, 'Test for correct DNS - Should Pass');

is( test('test@tri-llama.com'), 1, 'Test non-rfc compliant DNS using cname for MX - Should Pass');

is( test('test@mail.mcgrail.com'), 1, 'Test for implicit MX by A record - Should Pass');

is( test('AirchieChalmers@londo.cysticercus.com'), 1, 'Test for something that was throwing an error in v1 where we need to discard the first answer on a CNAME domain - Should Pass');

is( test('OlgaCraft@barbequesauceofthemonthclub.com'), 1, 'Test for something that was throwing an error in v1 where we need to discard the first answer on a CNAME domain - Should Pass');

is( test('test@test.peregrinehw.com'), 1, 'Test for the use of crazy things like 12.34.56.78. as the host name in DNS - Should Pass if $allow_ip_address_as_mx = 1');

is( test('god@va'), 1, 'Test for unusual top level domain setups like .va for the Vatican');

is( test('test@test6.peregrinehw.com'), 1, 'Test for a host that is configured with an MX of . but eventually has a good MX recorded (due to eNom.com (name-services.com) false positives - Should Pass');
