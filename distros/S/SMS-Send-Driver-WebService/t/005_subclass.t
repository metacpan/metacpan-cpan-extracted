# -*- perl -*-

use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 18;

{
  package #hide from CPAN
    SMS::Send::My::Driver;
  use base qw{SMS::Send::Driver::WebService};
}

my $service = SMS::Send::My::Driver->new;

isa_ok ($service, 'SMS::Send::My::Driver');
isa_ok ($service, 'SMS::Send::Driver::WebService');
isa_ok ($service, 'SMS::Send::Driver');
isa_ok ($service->cfg, 'Config::IniFiles');
is($service->cfg_section, "My::Driver", "cfg_section");
like($service->cfg_file, qr{\A(\.[/\\])?SMS-Send\.ini\Z}, "cfg_file");
isa_ok($service->cfg_path, "ARRAY");
is($service->cfg_path->[0], ".", "cfg_path[0]");

if ($^O eq 'MSWin32') {
  SKIP :{
    eval('use Win32');
    skip "Win32 not available", 1 if $@;
    is($service->cfg_path->[1], eval('Win32::GetFolderPath(Win32::CSIDL_WINDOWS)'), "cfg_path[1]");
  }
} else {
  SKIP: {
    eval('use Sys::Path');
    skip "Sys::Path not available", 1 if $@;
    is($service->cfg_path->[1], eval('Sys::Path->sysconfdir'), "cfg_path[1]");
  }
}

is($service->username,    'user_cfg_sub',        'username');
is($service->password,    'pass_cfg_sub',        'password');
is($service->host,        'host_cfg_sub',        'host');
is($service->protocol,    'protocol_cfg_sub',    'protocol');
is($service->port,        'port_cfg_sub',        'port');
is($service->script_name, 'script_name_cfg_sub', 'script_name');
is($service->url,         'url_cfg_sub',         'url');
is($service->warnings,    'warnings_cfg_sub',    'warnings');
is($service->debug,       'debug_cfg_sub',       'debug');
