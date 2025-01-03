# -*- perl -*-

use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 10;

BEGIN { use_ok( 'SMS::Send::Driver::WebService' ); }

my $service = SMS::Send::Driver::WebService->new(
                                                 username    => "user_new",
                                                 password    => "pass_new",
                                                 host        => "host_new",
                                                 protocol    => "protocol_new",
                                                 port        => "port_new",
                                                 script_name => "script_name_new",
                                                 warnings    => 'warnings_new',
                                                 debug       => 'debug_new',
                                                );

isa_ok ($service, 'SMS::Send::Driver::WebService');
isa_ok ($service, 'SMS::Send::Driver');
is($service->username   , 'user_new'       , 'username');
is($service->host       , 'host_new'       , 'host');
is($service->protocol   , 'protocol_new'   , 'protocol');
is($service->port       , 'port_new'       , 'port');
is($service->script_name, 'script_name_new', 'script_name');
is($service->warnings   , 'warnings_new'   , 'warnings');
is($service->debug      , 'debug_new'      , 'debug');
