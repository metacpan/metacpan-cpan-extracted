use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Tags::Output::Raw;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
eval {
	Tags::Output::Raw->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n",
	"Unknown parameter ''.");
clean();

# Test.
eval {
	Tags::Output::Raw->new('something' => 'value');
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	"Unknown parameter 'something'.");
clean();

# Test.
eval {
	Tags::Output::Raw->new('attr_delimeter' => '-');
};
is($EVAL_ERROR, "Bad attribute delimeter '-'.\n",
	"Bad attribute delimeter '-'.");
clean();

# Test.
eval {
	Tags::Output::Raw->new('auto_flush' => 1);
};
is($EVAL_ERROR, 'Auto-flush can\'t use without output handler.'."\n",
	'Auto-flush can\'t use without output handler.');
clean();

# Test.
eval {
	Tags::Output::Raw->new('output_handler' => '');
};
is($EVAL_ERROR, 'Output handler is bad file handler.'."\n",
	'Output handler is bad file handler.');
clean();

# Test.
my $obj = Tags::Output::Raw->new;
isa_ok($obj, 'Tags::Output::Raw');
