# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-OpenSRS-OMA.t'

#########################


use Test::More tests => 4;
BEGIN { use_ok('Net::OpenSRS::OMA') };

my $oma;

# test environment does not always have a valid SSL cert
$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

$oma = Net::OpenSRS::OMA->new(
  uri => 'https://admin.test.hostedemail.com/api/',
  user => 'bad_user@bad-domain.xom',
  password => 'bad_password',
  client => 'Net::OpenSRS::OMA Test Script\0.1'
);

isa_ok($oma, 'Net::OpenSRS::OMA');

my $response;
$response = $oma->get_user(user=>'nosuch@bad-domain.xom');

isa_ok($response, 'Net::OpenSRS::OMA::Response', 'Method call returns a Response object');

like($response->http_status, qr/^200/, 'Connected to server and got a successful response');



