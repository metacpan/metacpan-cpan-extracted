package Declared::WithFP;

use 5.036;
use warnings FATAL => q{all};

use Function::Parameters qw{:strict};
use Types::Standard      qw{Int Str};

# PPI does not know the keywords of Function::Parameters: it reads the subs and the final 1; as one statement,
# and a type before a named parameter as a label.
## no critic (Modules::RequireEndWithOne NamingConventions::Capitalization)

fun add( Int $x, Int $y = 1 ) {
    return $x + $y;
}

method greet( Str : $who, : $times = 1 ) {
    return $who x $times;
}

1;
