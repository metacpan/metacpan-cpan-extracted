use Test::Most 0.25;

use PerlX::bash ':all';

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use SkipUnlessBash;
use TestUtilFuncs qw< throws_error >;


my @list = 1..5;

is join('', head  3 => @list), "123", "head with positive arg works";
is join('', head -3 => @list), "12",  "head with negative arg works";
is join('', head  0 => @list), "",    "head with zero arg works";

is join('', tail -2 => @list), "45",   "tail with negative arg works";
is join('', tail +2 => @list), "2345", "tail with positive arg works";
is join('', tail  0 => @list), "",     "tail with zero arg works";


# ensure we don't go out of bounds with our lists
@list = 1..3;
my $count;

$count =()= head  5 => @list; is $count, 3, "no extraneous elements (head with positive arg)";
$count =()= head -5 => @list; is $count, 0, "no extraneous elements (head with negative arg)";

$count =()= tail -5 => @list; is $count, 3, "no extraneous elements (head with negative arg)";
$count =()= tail +5 => @list; is $count, 0, "no extraneous elements (head with positive arg)";

is join('', head  5 => @list),       "123", "stays in bounds (head with positive arg)";
is join('', head -5 => @list),          "", "stays in bounds (head with negative arg)";

is join('', tail -5 => @list),       "123", "stays in bounds (tail with negative arg)";
is join('', tail +5 => @list),          "", "stays in bounds (tail with positive arg)";


done_testing;
