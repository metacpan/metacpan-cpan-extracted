# Test correct operation of Net::Traces::TSH records_in()
#
use strict;
use Test;

BEGIN { plan tests => 3 };

use Net::Traces::TSH 0.13 qw( records_in );
ok(1);

# sample.tsh is a legit TSH trace file... err, at least it has an
# integer number of records.  This is simply a sanity check, there is
# no way to be 100% that  a file is indeed a TSH trace.
#

ok(records_in 't/sample_input/sample.tsh', 1000);

# In contrast, an arbitrary file should fail the same test
#
ok(! records_in 't/sample_output/sample.csv');
