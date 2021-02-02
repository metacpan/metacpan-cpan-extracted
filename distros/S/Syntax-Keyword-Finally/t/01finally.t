#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Keyword::Finally;

{
    my $x = "";
    {
        FINALLY { $x = "a" }
    }
    is($x, "a", 'FINALLY block is invoked');

    {
        FINALLY {
            $x = "";
            $x .= "abc";
            $x .= "123";
        }
    }
    is($x, "abc123", 'FINALLY block can contain multiple statements');

    {
       FINALLY {}
    }
    ok(1, 'Empty FINALLY block parses OK');
}

{
    my $x = "";
    {
        FINALLY { $x .= "a" }
        FINALLY { $x .= "b" }
        FINALLY { $x .= "c" }
    }
    is($x, "cba", 'FINALLY blocks happen in LIFO order');
}

{
    my $x = "";

    {
        FINALLY { $x .= "a" }
        $x .= "A";
    }

    is($x, "Aa", 'FINALLY blocks happen after the main body');
}

{
    my $x = "";

    foreach my $i (qw( a b c )) {
        FINALLY { $x .= $i }
    }

    is($x, "abc", 'FINALLY block happens for every iteration of foreach');
}

{
    my $x = "";

    my $cond = 0;
    if( $cond ) {
        FINALLY { $x .= "XXX" }
    }

    is($x, "", 'FINALLY block does not happen inside non-taken conditional branch');
}

{
    my $x = "";

    while(1) {
        last;
        FINALLY { $x .= "a" }
    }

    is($x, "", 'FINALLY block does not happen if entered but unencountered');
}

{
   my $x = "";

   my $counter = 1;
   {
      FINALLY { $x .= "A" }
      redo if $counter++ < 5;
   }

   is($x, "AAAAA", 'FINALLY block can happen multiple times');
}

{
    my $x = "";

    {
        FINALLY {
            $x .= "a";
            FINALLY {
                $x .= "b";
            }
        }
    }

    is($x, "ab", 'FINALLY block can contain another FINALLY');
}

{
    my $x = "";
    my $value = do {
        FINALLY { $x .= "before" }
        "value";
    };

    is($x, "before", 'FINALLY blocks run inside do { }');
    is($value, "value", 'FINALLY block does not disturb do { } value');
}

{
    my $x = "";
    my $sub = sub {
        FINALLY { $x .= "a" }
    };

    $sub->();
    $sub->();
    $sub->();

    is($x, "aaa", 'FINALLY block inside sub');
}

{
    my $x = "";
    my $sub = sub {
        return;
        FINALLY { $x .= "a" }
    };

    $sub->();

    is($x, "", 'FINALLY block inside sub does not happen if entered but returned early');
}

{
   my $x = "";

   sub after {
      $x .= "c";
   }

   sub before {
      $x .= "a";
      FINALLY { $x .= "b" }
      goto \&after;
   }

   before();

   is($x, "abc", 'FINALLY block invoked before tail-call');
}

# Sequencing with respect to variable cleanup

{
    my $var = "outer";
    my $x;
    {
        my $var = "inner";
        FINALLY { $x = $var }
    }

    is($x, "inner", 'FINALLY block captures live value of same-scope lexicals');
}

{
    my $var = "outer";
    my $x;
    {
        FINALLY { $x = $var }
        my $var = "inner";
    }

    is ($x, "outer", 'FINALLY block correctly captures outer lexical when only shadowed afterwards');
}

{
    our $var = "outer";
    {
        local $var = "inner";
        FINALLY { $var = "finally" }
    }

    is($var, "outer", 'FINALLY after localization still unlocalizes');
}

{
    our $var = "outer";
    {
        FINALLY { $var = "finally" }
        local $var = "inner";
    }

    is($var, "finally", 'FINALLY before localization overwrites');
}

# Interactions with exceptions

{
    my $x = "";
    my $sub = sub {
        FINALLY { $x .= "a" }
        die "Oopsie\n";
    };

    my $e = defined eval { $sub->(); 1 } ? undef : $@;

    is($x, "a", 'FINALLY block still runs during exception unwind');
    is($e, "Oopsie\n", 'Thrown exception still occurs after FINALLY');
}

# {
#     my $sub = sub {
#         FINALLY { die "Oopsie\n"; }
#         return "retval";
#     };
# 
#     my $e = defined eval { $sub->(); 1 } ? undef : $@;
# 
#     is($e, "Oopsie\n", 'FINALLY block can throw exception');
# }

{
    my $sub = sub {
        FINALLY { die "Oopsie 1\n"; }
        die "Oopsie 2\n";
    };

    my $e = defined eval { $sub->(); 1 } ? undef : $@;

    # TODO: Currently the first exception gets lost without even a warning
    #   We should consider what the behaviour ought to be here
    # This test is happy for either exception to be seen, does not care which
    like($e, qr/^Oopsie \d\n/, 'FINALLY block can throw exception during exception unwind');
}

# {
#     my $sub = sub {
#         while(1) {
#             FINALLY { return "retval" }
#             last;
#         }
#         return "wrong";
#     };
# 
#     my $e = defined eval { $sub->(); 1 } ? undef : $@;
#     like($e, qr/^Can't "return" out of a FINALLY block /,
#         'Cannot return out of FINALLY block');
# }

# {
#     my $sub = sub {
#         while(1) {
#             FINALLY { goto HERE }
#         }
#         HERE:
#     };
# 
#     my $e = defined eval { $sub->(); 1 } ? undef : $@;
#     like($e, qr/^Can't "goto" out of a FINALLY block /,
#         'Cannot goto out of FINALLY block');
# }

# {
#     my $sub = sub {
#         LOOP: while(1) {
#             FINALLY { last LOOP }
#         }
#     };
# 
#     my $e = defined eval { $sub->(); 1 } ? undef : $@;
#     like($e, qr/^Can't "last" out of a FINALLY block /,
#         'Cannot last out of FINALLY block');
# }

done_testing;
