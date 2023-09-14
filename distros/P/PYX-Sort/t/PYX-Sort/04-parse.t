use strict;
use warnings;

use File::Object;
use PYX::Sort;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Test::Output;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = PYX::Sort->new;
my $pyx_data = slurp($data_dir->file('ex1.pyx')->s);
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
		$obj->parse($pyx_data);
		return;
	},
	$right_ret,
	'Parse data from ex1.pyx file.',
);

# Test.
$pyx_data = slurp($data_dir->file('ex2.pyx')->s);
stdout_is(
	sub {
		$obj->parse($pyx_data);
		return;
	},
	$right_ret,
	'Parse data from ex2.pyx file.',
);
