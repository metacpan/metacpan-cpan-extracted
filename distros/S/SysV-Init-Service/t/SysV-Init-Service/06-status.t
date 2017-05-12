# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;
use SysV::Init::Service;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Service dir.
my $service_dir = File::Object->new->up->dir('services');

# Test.
my $obj = SysV::Init::Service->new(
	'service' => 'service1',
	'service_dir' => $service_dir->s,
);
my $ret = $obj->status;
is($ret, '0', 'Get service status.');

# Test.
$obj = SysV::Init::Service->new(
	'service' => 'service4',
	'service_dir' => $service_dir->s,
);
$ret = $obj->status;
is($ret, '3', "Service hasn't status.");
