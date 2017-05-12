use strict;
use warnings;

use Test::More 'tests' => 10;

use lib '.';

package t::ErrorParent::Child; {
    eval "use Object::InsideOut qw(t::ErrorParent);";
    Test::More::ok($@, 'Correctly fails on syntax error in parent');
}

package t::Child; {
    eval "use Object::InsideOut qw(t::Missing);";
    Test::More::ok($@, 'Correctly fails on missing parent');
}

package t::Missing::Child; {
    eval "use Object::InsideOut qw(t::Missing);";
    Test::More::ok($@, 'Correctly fails on missing parent');
}

package t::Child2; {
    eval 'use Object::InsideOut qw(t::EmptyParent);';
    Test::More::ok($@, 'Correctly fails on empty parent');
}

package t::EmptyParent::Child; {
    eval 'use Object::InsideOut qw(t::EmptyParent);';
    Test::More::ok($@, 'Correctly fails on empty parent');
}

package t::IntEmptyParent;
package t::IntChild; {
    eval 'use Object::InsideOut qw(t::IntEmptyParent);';
    Test::More::ok($@, 'Correctly fails on empty parent');
}

package t::IntEmptyParent::Child; {
    eval 'use Object::InsideOut qw(t::IntEmptyParent);';
    Test::More::ok($@, 'Correctly fails on empty parent');
}



# Test where parent is defined in an external file (e.g., t/Parent.pm) which
# hasn't be loaded yet, and the name of the child class starts with the the
# name of the parent class.  For example:
#       t::Parent
#           t::Parent::Child

package t::Parent::Child; {
    use Object::InsideOut qw(t::Parent);
}

package main;
MAIN:
{
    my $child = t::Parent::Child->new();
    isa_ok($child, 't::Parent::Child');
    isa_ok($child, 't::Parent');
    eval { $child->parent_func() };
    ok(!$@, 'child->parent_func()');
}

exit(0);

# EOF
