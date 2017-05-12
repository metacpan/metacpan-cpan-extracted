#     A   B
#    / \ /
#   C   D
#    \ /
#     E

use NEXT;

package A;
sub foo { print "called A::foo\n"; shift->NEXT::UNSEEN::foo() }

package B;
sub foo { print "called B::foo\n"; shift->NEXT::UNSEEN::foo() }

package C; @ISA = qw( A );
sub foo { print "called C::foo\n"; shift->NEXT::UNSEEN::foo() }

package D; @ISA = qw(A B);
sub foo { print "called D::foo\n"; shift->NEXT::UNSEEN::foo() }

package E; @ISA = qw(C D);
sub foo { print "called E::foo\n"; shift->NEXT::UNSEEN::foo() }

E->foo();
