# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;
use PYX::Sort;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Test::Output;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = PYX::Sort->new;
my $right_ret = <<"END";
(tag
Aattr1="value"
Aattr2="value"
Aattr3="value"
-text
)tag
END
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('ex1.pyx')->s);
		return;
	},
	$right_ret,
	'Parse ex1.pyx file.',
);

# Test.
stdout_is(
	sub {
		$obj->parse_file($data_dir->file('ex2.pyx')->s);
		return;
	},
	$right_ret,
	'Parse ex2.pyx file.',
);
