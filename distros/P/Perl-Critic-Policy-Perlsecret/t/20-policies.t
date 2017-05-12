use strict;
use warnings;
use Test::More;
use Perl::Critic::TestUtils qw( pcritique );

my $code;

# Venus
$code = <<'__CODE__';
    print 0+ '23a';
    #print +0 '23a'; should not be detected as is a comment
    print +0 '23a';
    is(scalar @vars, 0, 'Empty list');
}
__CODE__
is pcritique( 'Perlsecret', \$code ), 2, '2 x Venus expected';

# Babycart
$code = <<'__CODE__';
my $variable = @{[ qw( 1 2 3 ) ]};
for ( @{[ qw( 1 2 3 ) ]} ) { return $_ };
for ( @ { [ qw( 1 2 3 ) ] } ) { return $_ };
# baby cart @{[ ]}
{
    local $" = ',';
    %got = ( 'a' .. 'f' );
    is( "A @{[sort keys %got]} Z", "A a,c,e Z", '@{[ ]}' );
}
__CODE__
is pcritique( 'Perlsecret', \$code ), 4, '4 x Baby Cart expected';

# Bang Bang
$code = <<'__CODE__';
my $true  = !! 'a string';   # now 1
# ignore this comment !!
my $true2 = ! ! 'another string';
# This should NOT be detected as bang bang
# Test for issue #5
my $highlight =~ s!^\s+!!;
__CODE__
is pcritique( 'Perlsecret', \$code ), 2, '2 x Bang Bang';

# Eskimo Greeting - SKipped as only used in one liners

# Inch worm
$code = <<'__CODE__';
$x = 1.23;
print ~~$x;
print ~ ~ $x	;
__CODE__
is pcritique( 'Perlsecret', \$code ), 2, '2 x Inchworm';

# Inch worm on a stick
$code = <<'__CODE__';
$y = ~-$x * 4;
$y = -~$x * 4;
# $y = -~$x * 4;
$y = - ~ $x * 4;
__CODE__
is pcritique( 'Perlsecret', \$code ), 3, '3 x Inchworm on a stick';

# Space Station
$code = <<'__CODE__';
print -+- '23a';
#print -+- '23a';
print - + - '23a';
__CODE__
is pcritique( 'Perlsecret', \$code ), 2, '2 x Space station';

# Goatse
$code = <<'__CODE__';
$n =()= "abababab" =~ /a/;
#$n =()= "abababab" =~ /a/;
$n =($b)= "abababab" =~ /a/g;
$n = ( $b ) = "abababab" =~ /a/g;
# print "Dist($k,$k2)=($tri+1)/($min-1)=$Dist{$k}{$k2}\n";
__CODE__
is pcritique( 'Perlsecret', \$code ), 3, '3 x Goatse';

# Flaming X-Wing
$code = <<'__CODE__';
@data{@fields} =<>=~ $regexp;
@data{@fields} =<$luke>=~ $regexp;
__CODE__
is pcritique( 'Perlsecret', \$code ), 2, '2 x Flaming X-Wing';

# Kite
$code = <<'__CODE__';
@triplets = ( ~~<>, ~~<>, ~~<> );
__CODE__
is pcritique( 'Perlsecret', \$code ), 1, '1 x Kite';

# Ornate double-bladed sword
$code = <<'__CODE__';
<<m=~m>>

<<m=~m>>
The above should not be detected

m
;
__CODE__
is pcritique( 'Perlsecret', \$code ), 1, '1 x Ornate double-bladed sword';

# Flathead.
$code = <<'__CODE__';
$x -=!! $y;
# $x -=!  $y;
$x -=!  $y;
__CODE__
is pcritique( 'Perlsecret', \$code ), 2, '2 x Flathead';

# Phillips.
$code = <<'__CODE__';
$x +=!! $y;
$x +=!  $y;
__CODE__
is pcritique( 'Perlsecret', \$code ), 2, '2 x Phillips';

# Torx.
$code = <<'__CODE__';
$x *=!! $y;
$x *=!  $y;
__CODE__
is pcritique( 'Perlsecret', \$code ), 2, '2 x Torx';

# Pozidriv.
$code = <<'__CODE__';
$x x=!! $y;
$x x=!  $y;
__CODE__
is pcritique( 'Perlsecret', \$code ), 2, '2 x Pozidriv';

# Winking fat comma
$code = <<'__CODE__';
%hash = (
  APPLE   ,=>  "green",
  CHERRY  ,=>  "red",
  BANANA  ,=>  "yellow",
);
__CODE__
is pcritique( 'Perlsecret', \$code ), 1, '1 x Winking fat comma';

# Enterprise
$code = <<'__CODE__';
my @shopping_list = (
    'bread',
    'milk',
   ('apples'   )x!! ( $cupboard{apples} < 2 ),
   ('bananas'  )x!! ( $cupboard{bananas} < 2 ),
   ('cherries' )x!! ( $cupboard{cherries} < 20 ),
   ('tonic'    )x!! $cupboard{gin},
);
( return => $params{return} ) x !!$params{return};
__CODE__
is pcritique( 'Perlsecret', \$code ), 2, '2 x Enterprise';

# Key of truth
$code = <<'__CODE__';
my $true  = 0+!! 'a string';
__CODE__
is pcritique( 'Perlsecret', \$code ), 1, '1 x Key of truth';

# Abbott and Costello + Leaning Abbott and Costello
$code = <<'__CODE__';
my @shopping_list = (
    'bread',
    'milk',
    $this ||(),
    'apples'
);
my @shopping_list = (
    'bread',
    'milk',
    $that //(),
    'apples'
);
return $self->_has_session
    || ( $self->cookie($engine->cookie_name )
    && !$self->has_destroyed_session );
__CODE__
is pcritique( 'Perlsecret', \$code ), 2, '2 x Abbot and Costello';

done_testing;

=pod

Operator     Nickname                     Function
======================================================
0+           Venus                        numification
@{[ ]}       Babycart                     list interpolation
!!           Bang bang                    boolean conversion
}{           Eskimo greeting              END block for one-liners
~~           Inchworm                     scalar
~-           Inchworm on a stick          high-precedence decrement
-~           Inchworm on a stick          high-precedence increment
-+-          Space station                high-precedence numification
=( )=        Goatse                       scalar / list context
=< >=~       Flaming X-Wing               match input, assign captures
~~<>         Kite                         a single line of input
<<m=~m>> m ; Ornate double-bladed sword   multiline comment
-=!   -=!!   Flathead                     conditional decrement
+=!   +=!!   Phillips                     conditional increment
x=!   x=!!   Pozidriv                     conditional reset to ''
*=!   *=!!   Torx                         conditional reset to 0
,=>          Winking fat comma            non-stringifying fat comma
()x!!        Enterprise                   boolean list squash
0+!!         Key to the truth             numeric boolean conversion
||()         Abbott and Costello          remove false scalar from list
//()         Leaning Abbott and Costello  remove undef from list

=cut
