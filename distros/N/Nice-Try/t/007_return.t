# -*- perl -*-

use strict;
use warnings;

use Test::More qw( no_plan );

use Nice::Try;
# use Nice::Try debug => 6, debug_file => './dev/debug_return.pl', debug_code => 1;

# Credits to Steve Scaffidi for his test suit

# return from try
{
    my $after;

    is(
        ( sub {
            try { return "result" }
            catch {}
            $after++;
            return "nope";
        } )->(),
        "result",
        'return in try leaves containing function'
    );
    ok( !$after, 'code after try{return} is not invoked' );
}

# return from two nested try{}s
{
    my $after;

    is(
        ( sub {
            try {
                try { return "result" }
                catch {}
            }
            catch {}
            $after++;
            return "nope";
        } )->(),
        "result",
        'return in try{try{}} leaves containing function'
    );
    ok( !$after, 'code after try{try{return}} is not invoked' );
}

# return inside eval{} inside try{}
{
    my $rv = sub {
        my $two;
        try {
            my $one = eval { return 1 };
            $two = $one + 1;
        }
        catch {}
        return $two;
    }->();
    is(
        $rv,
        2,
        'return in eval{} inside try{} behaves as expected'
    );
}

# return from catch
{
    is(
        ( sub {
            try { die "oopsie" }
            catch { return "result" }
            return "nope";
        } )->(),
        "result",
        'return in catch leaves containing function'
    );
}

# return hash from try
{
    is(
        ref( sub
        {
            try
            {
                return( {} );
            }
            catch{ return( 'nope' ) }
        }->()),
        'HASH',
        'returning an hash'
    );
}

done_testing;
