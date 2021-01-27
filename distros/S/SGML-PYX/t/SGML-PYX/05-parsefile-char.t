use strict;
use warnings;

use File::Object;
use SGML::PYX;
use Test::More 'tests' => 4;
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

# Test.
SKIP: {
	skip '\'<\' in character data', 1;

$obj = SGML::PYX->new;
$right_ret = <<'END';
-for (var i = 0; i < results.length; i++) {alert(i);}\n
END
stdout_is(
	sub {
		$obj->parsefile($data_dir->file('char3.sgml')->s);
		return;
	},
	$right_ret,
	'Test character data with javascript (<).',
);
};
