# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;
use SysV::Init::Service;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Service dir.
my $service_dir = File::Object->new->up->dir('services');

# Test.
my $obj = SysV::Init::Service->new(
	'service' => 'service1',
	'service_dir' => $service_dir->s,
);
my $ret = $obj->name;
is($ret, 'service1', 'Get service name.');
