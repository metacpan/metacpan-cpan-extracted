use strict;
use warnings;
use Test::More;

# Switch::Declare is a lexical pragma: `switch` is only the keyword inside the
# lexical scope of a `use Switch::Declare`. Note this file does NOT `use` it at
# file scope, so we can prove the out-of-scope behaviour.

# a plain package sub named `switch` - must remain callable when the pragma
# is not in effect.
sub switch { return "sub(@{[join ',', @_]})" }

is( switch(1, 2), "sub(1,2)", "switch is an ordinary sub with no pragma in scope" );

{
    use Switch::Declare;
    my $r = switch (2) { case 1 { "one" } case 2 { "two" } default { "x" } };
    is( $r, "two", "switch is the keyword inside the pragma scope" );
}

# after the block closes, the pragma is out of scope again
is( switch(9), "sub(9)", "switch reverts to the ordinary sub after the scope" );

{
    use Switch::Declare;
    no Switch::Declare;
    is( switch(7), "sub(7)", "no Switch::Declare disables the keyword again" );
}

# nested: keyword in an inner block, sub in the surrounding scope
{
    my $inner;
    {
        use Switch::Declare;
        $inner = switch (1) { case 1 { "kw" } default { "no" } };
    }
    is( $inner, "kw", "keyword works in a nested pragma scope" );
    is( switch(3), "sub(3)", "outer scope still sees the sub" );
}

done_testing;
