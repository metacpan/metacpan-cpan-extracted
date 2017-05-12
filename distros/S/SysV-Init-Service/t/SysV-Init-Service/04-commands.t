# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;
use SysV::Init::Service;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Service dir.
my $service_dir = File::Object->new->up->dir('services');

# Test.
my $obj = SysV::Init::Service->new(
	'service' => 'service1',
	'service_dir' => $service_dir->s,
);
my @ret = $obj->commands;
is_deeply(
	\@ret,
	[
		'start',
		'status',
		'stop',
	],
	'Get multiple commands from service STDOUT.',
);

# Test.
$obj = SysV::Init::Service->new(
	'service' => 'service2',
	'service_dir' => $service_dir->s,
);
@ret = $obj->commands;
is_deeply(
	\@ret,
	[
		'start',
	],
	'Get one command from service STDOUT.',
);

# Test.
$obj = SysV::Init::Service->new(
	'service' => 'service3',
	'service_dir' => $service_dir->s,
);
@ret = $obj->commands;
is_deeply(
	\@ret,
	[
		'start',
		'stop',
	],
	'Get multiple commands from service STDERR.',
);
