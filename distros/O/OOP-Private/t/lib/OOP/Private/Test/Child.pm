use strict;
use warnings;
use 5.010;

package OOP::Private::Test::Child {
    use base "OOP::Private::Test::Parent";

    sub accessParentPrivate {
        shift -> SUPER::doPrivateStuff(shift);
    }

    # Redefinition
    sub doPrivateStuff: Private { 99999 }

    sub accessParentProtected {
        shift -> doProtectedStuff(shift);
    }
}

1
