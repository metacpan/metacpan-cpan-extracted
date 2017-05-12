
package whatever;

sub quote {
    return "'" . shift() . "'";
}

{ quote => \&quote }