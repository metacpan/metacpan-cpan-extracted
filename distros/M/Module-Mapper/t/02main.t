#!/usr/bin/perl -w

# Formal testing for Module::Mapper

use strict;
use warnings;
BEGIN {
	$| = 1;
	push @INC, './blib/lib';
}

use Test::More tests => 3, no_diag => 0;
use Module::Mapper;
use Data::Dumper;
use File::Path;
#
#	directory to map to
#
my $path = './t/project';
#
#	flag to save output
#
my $saveAll = 1;

my $modules = find_sources( Output => './t/project' );
my $expected = {
'./bin/mapmodule' => [
'./bin/mapmodule',
'./t/project/bin/mapmodule'
],
'Module::Mapper' => [
'./lib/Module/Mapper.pm',
'./t/project/blib/Module/Mapper.pm',
'./lib/Module/Mapper.pod',
'./t/project/blib/Module/Mapper.pod'
]
};

saveIt('mapper1.out', Dumper($modules));

is_deeply($modules, $expected, 'find_sources(project mode)');

$modules = find_sources(
	Output => './t/project',
	Libs => [ './lib' ],
	Scripts => [ './bin/mapmodules' ],
	Modules => [ 'Module::Mapper', 'File::Path' ],
	UseINC => 1,
	IncludePOD => 1,
	);
$expected = {
'./bin/mapmodules' => [
'./bin/mapmodules',
'./t/project/bin/mapmodules'
],
'Module::Mapper' => [
'./lib/Module/Mapper.pm',
'./t/project/blib/Module/Mapper.pm',
'./lib/Module/Mapper.pod',
'./t/project/blib/Module/Mapper.pod'
],
'File::Path' => [
'C:/Perl/lib/File/Path.pm',
'./t/project/lib/File/Path.pm'
]
};

saveIt('mapper2.out', Dumper($modules));

ok(
(exists $modules->{'./bin/mapmodules'}) &&
($#{$modules->{'./bin/mapmodules'}} == 1) &&
(exists $modules->{'Module::Mapper'}) &&
($#{$modules->{'Module::Mapper'}} == 3) &&
(exists $modules->{'File::Path'}) &&
($#{$modules->{'File::Path'}} == 1),
, 'find_sources(explicit modules)');

$modules = find_sources(
	All => 1,
	Output => './t/project',
	Scripts => [ './bin/mapmodules' ],
	Libs => [ './lib' ],
	Modules => [ 'Module' ],
	UseINC => 1,
	IncludePOD => 1,
	);

saveIt('mapper3.out', Dumper($modules));

$expected = {
'./bin/mapmodules' => [
'./bin/mapmodules',
'./t/project/bin/mapmodules'
],
'Module::Mapper' => [
'./lib/Module/Mapper.pm',
'./t/project/blib/Module/Mapper.pm',
'./lib/Module/Mapper.pod',
'./t/project/blib/Module/Mapper.pod'
]
};

is_deeply($modules, $expected, 'find_sources(namespace)');

sub saveIt {
	return unless $saveAll;
	open OUTF, ">$_[0]" or die $!;
	print OUTF $_[1];
	close OUTF;
}
