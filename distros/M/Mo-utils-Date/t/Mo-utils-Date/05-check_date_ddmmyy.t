use strict;
use warnings;

use DateTime;
use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::Date qw(check_date_ddmmyy);
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $self = {'key' => '201113'};
my $ret = check_date_ddmmyy($self, 'key');
is($ret, undef, "Date '201113' is right.");

# Test.
$self = {};
$ret = check_date_ddmmyy($self, 'key');
is($ret, undef, "Date key doesn't exist.");

# Test.
$self = {'key' => undef};
$ret = check_date_ddmmyy($self, 'key');
is($ret, undef, "Date key is undefined.");

# Test.
$self = {'key' => 'foo'};
eval {
	check_date_ddmmyy($self, 'key');
	
};
is($EVAL_ERROR, "Parameter 'key' is in bad date format.\n",
	"Parameter 'key' is in bad format (foo).");
clean();

# Test.
$self = {'key' => '111313'};
eval {
	check_date_ddmmyy($self, 'key');
	
};
is($EVAL_ERROR, "Parameter 'key' is bad date.\n",
	"Parameter 'key' is bad date (111313).");
clean();

# Test.
$self = {'key' => '10213'};
eval {
	check_date_ddmmyy($self, 'key');
	
};
is($EVAL_ERROR, "Parameter 'key' is in bad date format.\n",
	"Parameter 'key' is in bad date format (10213).");
clean();
