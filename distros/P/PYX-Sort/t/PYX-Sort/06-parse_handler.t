use strict;
use warnings;

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
open my $pyx_handler, '<', $data_dir->file('ex1.pyx')->s;
stdout_is(
	sub {
		$obj->parse_handler($pyx_handler);
		return;
	},
	$right_ret,
	'Parse ex1.pyx file handler.',
);
close $pyx_handler;

# Test.
open $pyx_handler, '<', $data_dir->file('ex2.pyx')->s;
stdout_is(
	sub {
		$obj->parse_handler($pyx_handler);
		return;
	},
	$right_ret,
	'Parse ex2.pyx file handler.',
);
