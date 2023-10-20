use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use PYX::Stack;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Test::Output;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = PYX::Stack->new(
	'verbose' => 1,
);
my $right_ret = <<'END';
xml
xml/xml2
xml/xml2/xml3
xml/xml2
xml
END
open my $fh, '<', $data_dir->file('ex1.pyx')->s;
stdout_is(
	sub {
		$obj->parse_handler($fh);
		return;
	},
	$right_ret,
	'Simple stack tree.',
);
close $fh;

# Test.
$obj = PYX::Stack->new;
open $fh, '<', $data_dir->file('ex2.pyx')->s;
eval {
	$obj->parse_handler($fh);
};
is($EVAL_ERROR, "Stack has some elements.\n", 'Stack has some elements.');
clean();
close $fh;

# Test.
$obj = PYX::Stack->new(
	'bad_end' => 1,
);
open $fh, '<', $data_dir->file('ex3.pyx')->s;
eval {
	$obj->parse_handler($fh);
};
is($EVAL_ERROR, "Bad end of element.\n", 'Bad end of element.');
clean();
close $fh;

# Test.
# XXX This is a bit problematic.
$obj = PYX::Stack->new;
open $fh, '<', $data_dir->file('ex3.pyx')->s;
eval {
	$obj->parse_handler($fh);
};
is($EVAL_ERROR, "Stack has some elements.\n", 'Stack has some elements.');
clean();
close $fh;
