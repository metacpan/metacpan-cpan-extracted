use strict;
use warnings;

use File::Object;
use PYX::SGML::Raw;
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Test::Output;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = PYX::SGML::Raw->new;
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('start_element1.pyx')->s);
		return;
	},
	'<element',
);

# Test.
$obj = PYX::SGML::Raw->new;
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('start_element2.pyx')->s);
		return;
	},
	'<element par="val"',
);

# Test.
$obj = PYX::SGML::Raw->new;
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('start_element3.pyx')->s);
		return;
	},
	'<element par="val\nval"',
);
