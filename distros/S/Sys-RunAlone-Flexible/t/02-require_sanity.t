use strict;
use warnings;

use Test::More tests => 2;

# this will cause the END test to fail if S::R::F exited early
my $normal = 0;

# placing this in a BEGIN block like normal causes this test to fail
# because it alters how the code in S:R:F executes
require_ok('Sys::RunAlone::Flexible');

# this will only be set if no errors occurred with the require
$normal = 1;

exit;

END {
    ok( $normal, 'normal execution continued' )
      or BAIL_OUT '__END__ tag not detected properly with require';
}

# normally there would be an __END__ tag here but "require" shouldn't
# need it since code does not execute at that time. included here only
# for illustrative purposes
#__END__
