# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 10;

BEGIN { use_ok( 'SMS::Send::NANP::Raco_TMO' ); }

{
my $service = SMS::Send::NANP::Raco_TMO->new(
                                        username => "user",
                                        password => "pass",
                                       );

isa_ok ($service, 'SMS::Send::NANP::Raco_TMO');
isa_ok ($service, 'SMS::Send::Driver::WebService');
isa_ok ($service, 'SMS::Send::Driver');
is($service->username, 'user', 'username');
is($service->password, 'pass', 'password');
}
{
my $service = SMS::Send::NANP::Raco_TMO->new(
                                        _username => "user",
                                        _password => "pass",
                                       );

isa_ok ($service, 'SMS::Send::NANP::Raco_TMO');
isa_ok ($service, 'SMS::Send::Driver');
is($service->username, 'user', 'username');
is($service->password, 'pass', 'password');
}
