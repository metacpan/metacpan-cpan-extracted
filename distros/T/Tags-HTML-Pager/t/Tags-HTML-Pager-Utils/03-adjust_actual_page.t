use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Pager::Utils qw(adjust_actual_page);
use Test::More 'tests' => 10;
use Test::NoWarnings;

# Test.
my $ret = adjust_actual_page(undef, 0);
is($ret, undef, 'No input actual page (no pages).');

# Test.
$ret = adjust_actual_page(undef, 1);
is($ret, 1, 'No input actual page (1 page).');

# Test.
$ret = adjust_actual_page(1, 0);
is($ret, undef, 'Actual page = 1 (no pages).');

# Test.
$ret = adjust_actual_page(1, 1);
is($ret, 1, 'Actual page = 1 (1 page).');

# Test.
$ret = adjust_actual_page(2, 0);
is($ret, undef, 'Actual page = 2 (no pages).');

# Test.
$ret = adjust_actual_page(2, 1);
is($ret, 1, 'Actual page = 2 (1 page).');

# Test.
eval {
	adjust_actual_page(1, 'foo');
};
is($EVAL_ERROR, "Number of pages must be a positive number.\n",
	"Number of pages must be a positive number ('foo').");
clean();

# Test.
eval {
	adjust_actual_page(1, -1);
};
is($EVAL_ERROR, "Number of pages must be a positive number.\n",
	"Number of pages must be a positive number (-1).");
clean();

# Test.
eval {
	adjust_actual_page(1);
};
is($EVAL_ERROR, "Not defined number of pages.\n",
	"Not defined number of pages.");
clean();
