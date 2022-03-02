########################################################################
# test exporting to non-standard name
########################################################################
use v5.24;

use Test::More;

use Parallel::Queue qw( export=foobar );

ok   __PACKAGE__->can( 'foobar'     ), 'foobar exported';
ok ! __PACKAGE__->can( 'runqueue'   ), 'runqueue not exported';

done_testing;
__END__
