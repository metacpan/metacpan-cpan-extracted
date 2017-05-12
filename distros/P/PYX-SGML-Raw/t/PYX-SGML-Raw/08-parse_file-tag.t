# Pragmas.
use strict;
use warnings;

# Modules.
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
		$obj->parse_file($data_dir->file('tag1.pyx')->s);
		return;
	},
	'<tag></tag>',
);

# Test.
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('tag2.pyx')->s);
		return;
	},
	'<tag par="val"></tag>',
);

# Test.
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('tag3.pyx')->s);
		return;
	},
	'<tag par="val\nval"></tag>',
);
