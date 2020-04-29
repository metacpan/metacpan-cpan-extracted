use strict;
use warnings;

use File::Object;
use PYX::SGML::Raw;
use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Output;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = PYX::SGML::Raw->new;
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('end_element1.pyx')->s);
		return;
	},
	'</element>',
);
