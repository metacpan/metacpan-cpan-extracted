# BEGIN { unlink 't/orz.tc' }

# Need to invoke Module::Compile before Test::More
my $t; use lib ($t = -e 't' ? 't' : 'test'), 'inc';
use Module::Compile;

use Test::More tests => 5;

pass "Test runs";

ok ((-f "$t/orz.tc"), "Compiled file exists");

use Testorz;

fail "don't want this to run";

no Testorz;

pass "Second half of test runs";

END { unlink "$t/orz.tc" }
