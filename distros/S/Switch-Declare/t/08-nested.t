use strict;
use warnings;
use Test::More;
use Switch::Declare;

# nested switches
sub classify {
    my ($x, $y) = @_;
    return switch ($x) {
        case 1 { switch ($y) { case "a" { "1a" } default { "1?" } } }
        case 2 { "two" }
        default { "n/a" }
    };
}
is( classify(1,"a"), "1a",  "nested match" );
is( classify(1,"b"), "1?",  "nested default" );
is( classify(2,"x"), "two", "outer match" );
is( classify(9,"x"), "n/a", "outer default" );

# multiple switches in one lexical scope must not warn or collide
my $w = "";
local $SIG{__WARN__} = sub { $w .= $_[0] };
my $a = switch (1) { case 1 { "one" } default { "x" } };
my $b = switch (2) { case 2 { "two" } default { "x" } };
is( "$a$b", "onetwo", "two switches in one scope" );
is( $w, "", "no warnings from repeated switches in a scope" );

done_testing;
