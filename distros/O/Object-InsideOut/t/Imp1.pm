use strict;
use warnings;

package t::A; {
    use Object::InsideOut;
    # overriding import at this level will prevent users of this
    # class or users of child classes from getting their @ISA changed.
    #sub import {};
}


package t::AA; {
    use Object::InsideOut qw(t::A) ;
}

package t::AAA; {
    use Object::InsideOut qw(t::AA) ;
}

1;

# EOF
