# -*- perl -*-

use strict;
use warnings;

use Test::More qw( no_plan );

use Nice::Try;
# use Nice::Try debug => 6, debug_file => './dev/debug_finally_die.pl', debug_code => 1;

# Credits to Steve Scaffidi for his test suit

# finally does not disturb $@
{
    local $SIG{__WARN__} = sub {};

    ok( !eval {
        try {
            die "oopsie";
        }
        finally {
            die "double oops";
        }
        1;
    }, 'die in both try{} and finally{} is still fatal' );
    like( $@, qr/^oopsie at /, 'die in finally{} does not corrupt $@' );
}

done_testing;
