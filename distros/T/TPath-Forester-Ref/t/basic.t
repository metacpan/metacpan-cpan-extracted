# tests all the attributes provided by TPath::Forester::Ref and otherwise
# exercises its abilities

use strict;
use warnings;
use TPath::Forester::Ref;
use List::MoreUtils qw(natatime);

use Test::More tests => 27;

my $f = TPath::Forester::Ref->new;

my $ref = {
    a => [],
    b => {
        g => undef,
        h => { i => [ { l => 3, 4 => 5 }, 2 ], k => 1 },
        c => [qw(d e f)]
    }
};

# vanilla structs
my $iterator = iterate( <<'END', 2 );
//@array
3

//@hash
4

//@leaf
9

//@ref
7

//@non-ref
8

//@obj
0

//@num
4

//@str
3

//@key
9

//~[aeiouy]~
2

//*
15

//@defined
14

//@undef
1
END

count_test( $ref, $iterator );

# potential cycles
my $repeat = [qw(a b c)];
$ref = { d => $repeat, e => $repeat, f => $repeat };
$iterator = iterate( <<'END', 2 );
//*
7

//@repeat
2

//@repeat(1)
1

//@repeated
3
END

count_test( $ref, $iterator );

my $node = $f->path(q{//@repeat(1)})->select($ref);
is $node->tag, 'e', '@repeat(1) selected correct node';

# less common references
{
    no warnings;
    my $foo;
    $ref = [ \*foo, sub { }, \$foo ];
}
$iterator = iterate( <<'END', 2 );
//@glob
1

//@code
1

//@scalar
1
END

count_test( $ref, $iterator );

# simple classes
package Foo;
use Moose;

package Bar;
use Moose;

package Baz;
use Moose;
extends 'Bar';

package main;

$ref = [ Foo->new, Baz->new ];
$iterator = iterate( <<'END', 2 );
//@obj
2

//@isa('Foo')
1

//@isa('Foo','Bar')
2

//@isa('Baz')
1
END

count_test( $ref, $iterator );

# roles
package Quux;
use Moose::Role;

package Plugh;
use Moose;
with 'Quux';

package main;

$ref = { a => 1, b => Plugh->new };
$iterator = iterate( <<'END', 2 );
//@does('Quux')
1
END

count_test( $ref, $iterator );

# can
package Corge;
use Moose;
sub grault { }

package main;

$ref = [ Corge->new, Corge->new, Corge->new ];
$iterator = iterate( <<'END', 2 );
//@can('grault')
3
END

count_test( $ref, $iterator );

done_testing();

sub count_test {
    my ( $ref, $iterator ) = @_;
    while ( my ( $path, $count ) = $iterator->() ) {
        my @nodes = $f->path($path)->select($ref);
        is @nodes, $count, "correct number of nodes selected by $path";
    }
}

sub iterate {
    my ( $text, $n ) = @_;
    my @lines = grep { not /^\s*(?:#.*)?$/ } $text =~ /.*/mg;
    natatime $n, @lines;
}
