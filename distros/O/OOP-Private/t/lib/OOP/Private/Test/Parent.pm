use strict;
use warnings;
use 5.010;

package OOP::Private::Test::Parent {
    use OOP::Private;

    # -> int
    sub new { bless { number => pop }, pop }

    # -> int
    sub calculateSumWithPrivate {
        my $self = shift;
        $self -> doPrivateStuff(shift);
    }

    # -> int
    sub calculateSumWithProtected {
        my $self = shift;
        $self -> doProtectedStuff(shift);
    }

    sub doPrivateStuff:   Private   { shift -> {number} + shift @_ }
    sub doProtectedStuff: Protected { shift -> {number} + shift @_ }
}

1
