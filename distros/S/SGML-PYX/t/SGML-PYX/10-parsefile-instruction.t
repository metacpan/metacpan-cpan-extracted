use strict;
use warnings;

use File::Object;
use SGML::PYX;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Test::Output;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = SGML::PYX->new;
my $right_ret = <<'END';
?target code
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('instruction1.sgml')->s);
		return;
	},
	$right_ret,
	'Test instruction.',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
?target data\ndata
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('instruction2.sgml')->s);
		return;
	},
	$right_ret,
	'Test advanced instruction.',
);
