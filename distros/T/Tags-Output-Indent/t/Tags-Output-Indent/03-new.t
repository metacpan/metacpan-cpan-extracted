# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Tags::Output::Indent;
use Test::More 'tests' => 6;

# Test.
my $obj;
eval {
	$obj = Tags::Output::Indent->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n");

# Test.
eval {
	$obj = Tags::Output::Indent->new('something' => 'value');
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n");

# Test.
eval {
	$obj = Tags::Output::Indent->new('attr_delimeter' => '-');
};
is($EVAL_ERROR, "Bad attribute delimeter '-'.\n");

# Test.
eval {
	$obj = Tags::Output::Indent->new('auto_flush' => 1);
};
is($EVAL_ERROR, 'Auto-flush can\'t use without output handler.'."\n");

# Test.
eval {
	$obj = Tags::Output::Indent->new('output_handler' => '');
};
is($EVAL_ERROR, 'Output handler is bad file handler.'."\n");

# Test.
$obj = Tags::Output::Indent->new;
isa_ok($obj, 'Tags::Output::Indent');
