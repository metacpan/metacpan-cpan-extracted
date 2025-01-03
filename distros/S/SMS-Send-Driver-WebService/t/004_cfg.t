# -*- perl -*-

use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 18;

BEGIN { use_ok( 'SMS::Send::Driver::WebService' ); }

my $service = SMS::Send::Driver::WebService->new;

isa_ok ($service, 'SMS::Send::Driver::WebService');
isa_ok ($service, 'SMS::Send::Driver');
isa_ok ($service->cfg, 'Config::IniFiles');
is($service->cfg_section, "Driver::WebService", "cfg_section");
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

is($service->username,    'user_cfg',        'username');
is($service->password,    'pass_cfg',        'password');
is($service->host,        'host_cfg',        'host');
is($service->protocol,    'protocol_cfg',    'protocol');
is($service->port,        'port_cfg',        'port');
is($service->script_name, 'script_name_cfg', 'script_name');
is($service->url,         'url_cfg',         'url');
is($service->warnings,    'warnings_cfg',    'warnings');
is($service->debug,       'debug_cfg',       'debug');
