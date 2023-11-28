use strict;
use warnings;

use DateTime;
use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::Date qw(check_date_dmy);
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $self = {'date' => '20.11.1977'};
my $ret = check_date_dmy($self, 'date');
is($ret, undef, "Date '20.11.1977' is right.");

# Test.
$self = {'date' => '2.11.2023'};
$ret = check_date_dmy($self, 'date');
is($ret, undef, "Date '2.11.2023' is right.");

# Test.
$self = {'date' => '02.11.2023'};
$ret = check_date_dmy($self, 'date');
is($ret, undef, "Date '02.11.2023' is right.");

# Test.
$self = {'date' => '11.2.2023'};
$ret = check_date_dmy($self, 'date');
is($ret, undef, "Date '11.2.2023' is right.");

# Test.
$self = {'date' => '11.02.2023'};
$ret = check_date_dmy($self, 'date');
is($ret, undef, "Date '11.02.2023' is right.");

# Test.
$self = {'date' => 'foo'};
eval {
	check_date_dmy($self, 'date');
	
};
is($EVAL_ERROR, "Parameter 'date' is in bad format.\n",
	"Parameter 'date' is in bad format (foo).");
clean();

# Test.
$self = {'date' => '11.13.1989'};
eval {
	check_date_dmy($self, 'date');
	
};
is($EVAL_ERROR, "Parameter 'date' is bad date.\n",
	"Parameter 'date' is bad date (11.13.1989).");
clean();
