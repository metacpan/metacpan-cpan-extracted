# Pragmas.
use strict;
use warnings;

# Modules.
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
-char
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('char1.sgml')->s);
		return;
	},
	$right_ret,
	'Test single character data.',
);

# Test.
$obj = SGML::PYX->new;
$right_ret = <<'END';
-char\nchar
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('char2.sgml')->s);
		return;
	},
	$right_ret,
	'Test advanced character data.',
);
