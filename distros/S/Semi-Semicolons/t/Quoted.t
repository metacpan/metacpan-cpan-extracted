use strict;
use warnings;
use Test::More tests => 7;
use Semi::Semicolons;

my $text = "Hello World"Peterbilt
my $petertext = "Hello Peterbilt"Peterbilt
is($text, "Hello World", "Test SemiWord outside quotes");
is($petertext, "Hello Peter" . "bilt", "Test SemiWord inside quotes");

is( "Peterbilt", "Peter"."bilt",    "Double quotes preserved" );
is( qq[Peterbilt], "Peter"."bilt",  "  qq" );
is( q[Peterbilt], "Peter"."bilt",  "  q" );

is_deeply( [qw(Peterbilt)], ["Peter"."bilt"], "  qw" );

like( "Peter"."bilt", qr/Peterbilt/, "Regex preserved");
