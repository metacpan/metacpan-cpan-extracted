# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 11;

BEGIN { use_ok( 'SMS::Send::NANP::TextPower' ); }

{
my $service = SMS::Send::NANP::TextPower->new(
                                        username => "user",
                                        password => "pass",
                                        campaign => 'camp',
                                       );

isa_ok ($service, 'SMS::Send::NANP::TextPower');
isa_ok ($service, 'SMS::Send::Driver');
is($service->username, 'user', 'username');
is($service->password, 'pass', 'password');
is($service->campaign, 'camp', 'campaign');
}
{
my $service = SMS::Send::NANP::TextPower->new(
                                        _username => "user",
                                        _password => "pass",
                                        _campaign => 'camp',
                                       );

isa_ok ($service, 'SMS::Send::NANP::TextPower');
isa_ok ($service, 'SMS::Send::Driver');
is($service->username, 'user', 'username');
is($service->password, 'pass', 'password');
is($service->campaign, 'camp', 'campaign');
}
