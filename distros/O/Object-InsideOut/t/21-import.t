use strict;
use warnings;

use Test::More 'tests' => 7;

package main;
MAIN:
{
    use lib 't';
    use Imp1;
    use Imp2;

    is_deeply( \@main::ISA, [], 
            '@main::ISA result=' . join(', ', @main::ISA));

    is_deeply( \@t::A::ISA, [ 'Object::InsideOut' ], 
            '@t::A::ISA result=' . join(', ', @t::A::ISA));

    is_deeply( \@t::AA::ISA, [ 't::A' ], 
            '@t::AA::ISA result=' . join(', ', @t::AA::ISA));

    is_deeply( \@t::AAA::ISA, [ 't::AA' ], 
            '@t::AAA::ISA result=' . join(', ', @t::AAA::ISA));

    is_deeply( \@t::AA::ISA, [ 't::A' ], 
            '@t::AA::ISA result=' . join(', ', @t::AA::ISA));

    is_deeply( \@t::A_also::ISA, [ 't::A' ], 
            '@t::A_also::ISA result=' . join(', ', @t::A_also::ISA));

    is_deeply( \@t::AB::ISA, [ 't::A', 't::B' ], 
            '@t::AB::ISA result=' . join(', ', @t::AB::ISA));
}

exit(0);


# Multiple inheritance
package t::AB; {
    use Object::InsideOut qw( t::A t::B ) ;
}

# Embedded class inheritance test
package t::A_also; {
    use Object::InsideOut qw( t::A ) ;

    my @foo :Field();

    my %init_args :InitArgs = ( foo => {FIELD => \@foo});

    sub init :Init {}
}

# EOF
