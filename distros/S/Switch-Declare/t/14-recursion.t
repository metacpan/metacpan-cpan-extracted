use strict;
use warnings;
use Test::More;
use Switch::Declare;

# Re-entrancy: the evaluate-once temp lives in the caller's pad, and the
# dispatch table is a shared package hash - both must be correct under
# recursion and loops.

# recursive switch (expression scrutinee -> temp path)
sub fib {
    my $n = shift;
    return switch ($n) {
        case 0 { 0 }
        case 1 { 1 }
        default { fib($n - 1) + fib($n - 2) }
    };
}
is( fib(10), 55, "recursive switch (temp path)" );

# recursive switch with a string dispatch table (>= 4 arms)
sub depth {
    my ($node, $d) = @_;
    return switch ($node) {
        case "leaf" { $d }
        case "a"    { $d }
        case "b"    { $d }
        case "c"    { $d }
        default     { depth("leaf", $d + 1) }
    };
}
is( depth("x", 0), 1, "recursive switch (dispatch path)" );

# switch driven in a tight loop, accumulating
my @keys = ("a", "b", "c", "d", "z");
my $sum = "";
for my $k (@keys) {
    $sum .= switch ($k) {
        case "a" { "A" } case "b" { "B" } case "c" { "C" }
        case "d" { "D" } default { "?" }
    };
}
is( $sum, "ABCD?", "switch in a loop (dispatch path)" );

# nested recursion through grep
sub classify {
    my @in = @_;
    return grep {
        switch ($_) { case "ok" { 1 } case "fine" { 1 } default { 0 } }
    } @in;
}
my @good = classify("ok", "bad", "fine", "no");
is_deeply( [@good], ["ok", "fine"], "switch inside grep" );

done_testing;
