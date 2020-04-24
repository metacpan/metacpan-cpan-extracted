use strict;
use warnings;

use File::Object;
use SGML::PYX;
use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Output;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = SGML::PYX->new;
my $right_ret = <<'END';
?xml version="1.0" encoding="UTF-8"
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('xml1.sgml')->s);
		return;
	},
	$right_ret,
	'Test XML definition.',
);
