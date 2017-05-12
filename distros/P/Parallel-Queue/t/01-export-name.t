########################################################################
# test exporting to non-standard name
########################################################################

use v5.10;
use strict;

use Test::More qw( tests 2 );

use Parallel::Queue qw( export=foobar );

ok   __PACKAGE__->can( 'foobar'     ), 'foobar exported';
ok ! __PACKAGE__->can( 'runqueue'   ), 'runqueue not exported';

__END__
