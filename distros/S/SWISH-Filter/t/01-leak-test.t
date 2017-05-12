use strict;
use warnings;
use constant HAS_LEAKTRACE => eval { require Test::LeakTrace };
use Test::More HAS_LEAKTRACE
    ? ( tests => 2 )
    : ( skip_all => 'require Test::LeakTrace' );
use Test::LeakTrace;

#use Devel::LeakGuard::Object qw( GLOBAL_bless :at_end leakguard );

use_ok('SWISH::Filter');

SKIP: {

    unless ( $ENV{TEST_LEAKS} ) {
        skip "set TEST_LEAKS to test memory leaks", 1;
    }
    leaks_cmp_ok {
        #diag("start block");
        my $filter = SWISH::Filter->new;
        #diag("new SWISH::Filter");
        #$filter = undef;
    }
    '<', 1;

}
