use strict;
use warnings;
use Test::More;
use Switch::Declare;

# the scrutinee must be evaluated exactly once, even with many arms
my $calls = 0;
sub topic { $calls++; return "c" }

my $r = switch (topic()) {
    case "a" { "A" }
    case "b" { "B" }
    case "c" { "C" }
    case "d" { "D" }
    default  { "Z" }
};
is( $r, "C", "matched correct arm" );
is( $calls, 1, "scrutinee evaluated exactly once" );

# even when nothing matches (statement form; arms have side effects)
$calls = 0;
my @seen;
switch (topic()) { case "x" { push @seen, "x" } case "y" { push @seen, "y" } };
is( $calls, 1, "evaluated once on no-match too" );
is( "@seen", "", "no arm ran on no-match" );

# A statement-form switch with no default must not warn about a "useless"
# implicit undef tail in void context.
{
    my $warn = "";
    local $SIG{__WARN__} = sub { $warn .= $_[0] };
    my $v = "a";
    switch ($v) { case "a" { push @seen, 1 } case "b" { push @seen, 2 } };
    is( $warn, "", "statement-form switch without default does not warn" );
}

done_testing;
