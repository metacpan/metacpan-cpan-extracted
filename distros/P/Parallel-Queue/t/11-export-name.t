########################################################################
# test exporting to non-standard name
########################################################################
use v5.24;

use Test::More;

use Parallel::Queue::Manager;

ok ! __PACKAGE__->can( 'runqueue'   ), 'runqueue not exported';

done_testing;
__END__
