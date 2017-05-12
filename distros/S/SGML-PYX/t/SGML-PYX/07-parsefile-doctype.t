# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;
use SGML::PYX;
use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Output;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = SGML::PYX->new;
# TODO Not supported now.
my $right_ret = <<'END';
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('doctype1.sgml')->s);
		return;
	},
	$right_ret,
	'Test doctype.',
);
