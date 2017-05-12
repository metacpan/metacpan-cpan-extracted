# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 19;

BEGIN { use_ok( 'SMS::Send::Kannel::SMSbox' ); }

{
my $service = SMS::Send::Kannel::SMSbox->new(
                                     username    => "user",
                                     password    => "pass",
                                     protocol    => 'https',
                                     host        => 'host',
                                     port        => '8080',
                                     script_name => '/script',
                                     );

isa_ok ($service, 'SMS::Send::Kannel::SMSbox');
isa_ok ($service, 'SMS::Send::Driver');
is($service->username, 'user', 'username');
is($service->password, 'pass', 'password');
is($service->protocol, 'https', 'protocol');
is($service->host, 'host', 'host');
is($service->port, '8080', 'port');
is($service->script_name, '/script', 'script_name');
is($service->url, 'https://host:8080/script', 'url');
}
{
my $service = SMS::Send::Kannel::SMSbox->new(
                                     _username => "user",
                                     _password => "pass",
                                     _protocol    => 'https',
                                     _host        => 'host',
                                     _port        => '8080',
                                     _script_name => '/script',
                                    );

isa_ok ($service, 'SMS::Send::Kannel::SMSbox');
isa_ok ($service, 'SMS::Send::Driver');
is($service->username, 'user', 'username');
is($service->password, 'pass', 'password');
is($service->protocol, 'https', 'protocol');
is($service->host, 'host', 'host');
is($service->port, '8080', 'port');
is($service->script_name, '/script', 'script_name');
is($service->url, 'https://host:8080/script', 'url');
}
