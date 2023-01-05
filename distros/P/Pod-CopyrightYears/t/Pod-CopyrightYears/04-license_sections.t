use strict;
use warnings;

use File::Object;
use Pod::CopyrightYears;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data')->set;

# Test.
my $obj = Pod::CopyrightYears->new(
	'pod_file' => $data_dir->file('Ex1.pm')->s,
);
my @sections = $obj->license_sections;
is(scalar @sections, 1, 'Found one section (Ex1).');
$data_dir->reset;

# Test.
$obj = Pod::CopyrightYears->new(
	'pod_file' => $data_dir->file('Ex2.pm')->s,
);
@sections = $obj->license_sections;
is(scalar @sections, 0, 'Found zero sections (Ex2).');
$data_dir->reset;

# Test.
$obj = Pod::CopyrightYears->new(
	'pod_file' => $data_dir->file('Ex3.pm')->s,
	'section_names' => [
		'LICENSE',
	],
);
@sections = $obj->license_sections;
is(scalar @sections, 1, 'Found one section (Ex3).');
$data_dir->reset;
