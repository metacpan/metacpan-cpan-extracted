use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::Unicode qw(check_array_unicode_block);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => [
		'Latin Extended-A',
		'Latin Extended-B',
	],
};
my $ret = check_array_unicode_block($self, 'key');
is($ret, undef, 'Right Unicode block is present (Latin Extended-A).');

# Test.
$self = {};
$ret = check_array_unicode_block($self, 'key');
is($ret, undef, 'No Unicode block is present.');

# Test.
$self = {
	'key' => 'bad',
};
eval {
	check_array_unicode_block($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a array.\n",
	"Parameter 'key' must be a array (bad).");
clean();

# Test.
$self = {
	'key' => ['bad'],
};
eval {
	check_array_unicode_block($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' contains invalid Unicode block.\n",
	"Parameter 'key' contains invalid Unicode block (bad).");
clean();
