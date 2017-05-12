# -*- perl -*-

use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 17;

BEGIN { use_ok( 'SMS::Send::Driver::WebService' ); }

{
my $service = SMS::Send::Driver::WebService->new(
                                                 cfg         => "",
                                                 host        => "host_new",
                                                 protocol    => "protocol_new",
                                                 port        => "port_new",
                                                 script_name => "script_name_new",
                                                 url         => "overrides_host_protocol_port_script_name",
                                                );

isa_ok ($service, 'SMS::Send::Driver::WebService');
isa_ok ($service, 'SMS::Send::Driver');
is($service->host       , 'host_new'       , 'host');
is($service->protocol   , 'protocol_new'   , 'protocol');
is($service->port       , 'port_new'       , 'port');
is($service->script_name, 'script_name_new', 'script_name');

is($service->url, "overrides_host_protocol_port_script_name", "url");
}

{
my $service = SMS::Send::Driver::WebService->new(
                                                 cfg         => "",
                                                 host        => "host",
                                                 protocol    => "http",
                                                 port        => "123",
                                                 script_name => "/foo/bar",
                                                );

isa_ok ($service, 'SMS::Send::Driver::WebService');
isa_ok ($service, 'SMS::Send::Driver');
is($service->host       , 'host'       , 'host');
is($service->protocol   , 'http'   , 'protocol');
is($service->port       , '123'       , 'port');
is($service->script_name, '/foo/bar', 'script_name');

isa_ok($service->url, "URI", "url");
is($service->url, "http://host:123/foo/bar", "url");

is($service->url("http://host:123/foo/bar/baz"), "http://host:123/foo/bar/baz", "url");
}


