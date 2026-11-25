package Big;

# Numbers under use bigint, which makes every numeric literal a Math::BigInt object, and a constant that holds a reference.

use 5.036;
use warnings FATAL => q{all};

# The pragma is imported for its effect on literals, and the constant is a case under test.
## no critic (ProhibitUnusedImports PreferredModules)
use bigint;
use constant PAIR => [ 1, 2 ];

sub literal {
    return 5;
}

sub sum {
    my ($x) = @_;
    return $x + 1;
}

sub sized {
    my ($text) = @_;
    no bigint;
    return length $text;
}

1;
