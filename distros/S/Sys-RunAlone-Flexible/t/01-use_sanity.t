use strict;
use warnings;

use Test::More tests => 3;

BEGIN { use_ok('Sys::RunAlone::Flexible'); }

# this will cause the END test to fail if S::R::F exited early
my $normal = 1;

END {
    is( $Sys::RunAlone::Flexible::pkg, 'main', 'called from main package' );
    ok( $normal, 'normal execution continued' )
      or BAIL_OUT '__END__ tag not detected properly';
}

exit;

# this tag MUST be present for the test script to execute
__END__
