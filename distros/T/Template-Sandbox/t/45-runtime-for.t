#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox;

plan tests => 36;

my ( $template, $syntax );

#
#  1: <: for x in 2 :>.<: endfor :>
$syntax = "<: for x in 2 :>.<: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '...', 'for constant numeric set do constant content' );

#
#  2: <: for x in y :>.<: endfor :>
$syntax = "<: for x in y :>.<: endfor :>";
$template = Template::Sandbox->new();
$template->add_var( y => 4 );
$template->set_template_string( $syntax );
is( ${$template->run()}, '.....', 'for variable numeric set do constant content' );

#
#  3: <: for x in 2 :><: expr x :>.<: endfor :>
$syntax = "<: for x in 2 :><: expr x :>.<: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '0.1.2.', 'for constant numeric set do loop var content' );

#
#  4: <: for x in y :><: expr x :> in <: expr y :>.<: endfor :>
$syntax = "<: for x in y :><: expr x :> in <: expr y :>.<: endfor :>";
$template = Template::Sandbox->new();
$template->add_var( y => 4 );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0 in 4.1 in 4.2 in 4.3 in 4.4 in 4.', 'for variable numeric set do loop var content' );

#
#  5-6: does __first__ work?
$syntax = "<: for x in 4 :><: expr x.__first__ :><: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '10000', 'x.__first__' );

$syntax = "<: for x in 4 :><: expr x[ '__first__' ] :><: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '10000', "x[ '__first__' ]" );

#
#  7-8: does __inner__ work?
$syntax = "<: for x in 4 :><: expr x.__inner__ :><: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '01110', 'x.__inner__' );

$syntax = "<: for x in 4 :><: expr x[ '__inner__' ] :><: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '01110', "x[ '__inner__' ]" );

#
#  9-10: does __last__ work?
$syntax = "<: for x in 4 :><: expr x.__last__ :><: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '00001', 'x.__last__' );

$syntax = "<: for x in 4 :><: expr x[ '__last__' ] :><: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '00001', "x[ '__last__' ]" );

#
#  11-12: does __odd__ work?
$syntax = "<: for x in 4 :><: expr x.__odd__ :><: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '01010', 'x.__odd__' );

$syntax = "<: for x in 4 :><: expr x[ '__odd__' ] :><: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '01010', "x[ '__odd__' ]" );

#
#  13-14: does __even__ work?
$syntax = "<: for x in 4 :><: expr x.__even__ :><: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '10101', 'x.__even__' );

$syntax = "<: for x in 4 :><: expr x[ '__even__' ] :><: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '10101', "x[ '__even__' ]" );

#
#  15-16: does __counter__ work?
$syntax = "<: for x in 4 :><: expr x.__counter__ :><: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '01234', 'x.__counter__' );

$syntax = "<: for x in 4 :><: expr x[ '__counter__' ] :><: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '01234', "x[ '__counter__' ]" );

#  These two could break if template functions are broken.

#
#  17-18: does __prev__ work?
$syntax = "<: for x in 4 :><: if defined( x.__prev__ ) :><: expr x.__prev__ :><: else :>[undef]<: endif :><: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '[undef]0123', 'x.__prev__' );

$syntax = "<: for x in 4 :><: if defined( x[ '__prev__' ] ) :><: expr x[ '__prev__' ] :><: else :>[undef]<: endif :><: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '[undef]0123', "x[ '__prev__' ]" );

#
#  19-20: does __next__ work?
$syntax = "<: for x in 4 :><: if defined( x.__next__ ) :><: expr x.__next__ :><: else :>[undef]<: endif :><: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '1234[undef]', 'x.__next__' );

$syntax = "<: for x in 4 :><: if defined( x[ '__next__' ] ) :><: expr x[ '__next__' ] :><: else :>[undef]<: endif :><: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '1234[undef]', "x[ '__next__' ]" );

#
#  21: loop across array
$syntax = "<: for x in y :><: expr x :>/<: endfor :>";
$template = Template::Sandbox->new();
$template->add_var( y => [ qw/one two three/ ] );
$template->set_template_string( $syntax );
is( ${$template->run()}, 'one/two/three/', 'for array show value' );

#
#  22: loop across hash keys (alpha sorted by keys)
$syntax = "<: for x in y :><: expr x :>-<: endfor :>";
$template = Template::Sandbox->new();
$template->add_var( y => { one => 'ONE', two => 'TWO', three => 'THREE' } );
$template->set_template_string( $syntax );
is( ${$template->run()}, 'one-three-two-', 'for hash show keys' );

#
#  23: loop across hash keys and values (alpha sorted by keys)
$syntax = "<: for x in y :><: expr x :> => <: expr x.__value__ :>, <: endfor :>";
$template = Template::Sandbox->new();
$template->add_var( y => { one => 'ONE', two => 'TWO', three => 'THREE' } );
$template->set_template_string( $syntax );
is( ${$template->run()}, 'one => ONE, three => THREE, two => TWO, ', 'for hash show keys => values' );

#
#  24: nested loops across independent hashes (alpha sorted by keys)
$syntax = "<: for x in y :><: expr x :> => <: expr x.__value__ :>(<: for a in b :><: expr a :> => <: expr a.__value__ :>,<: endfor :>) <: endfor :>";
$template = Template::Sandbox->new();
$template->add_var( y => { one => 'ONE', two => 'TWO', three => 'THREE' } );
$template->add_var( b => { aaa => 'AAA', bbb => 'BBB', ccc => 'CCC' } );
$template->set_template_string( $syntax );
is( ${$template->run()}, 'one => ONE(aaa => AAA,bbb => BBB,ccc => CCC,) three => THREE(aaa => AAA,bbb => BBB,ccc => CCC,) two => TWO(aaa => AAA,bbb => BBB,ccc => CCC,) ', 'nested-for independent-hashes' );

#
#  25: nested loops across nested hashes (alpha sorted by keys)
$syntax = "<: for x in y :><: expr x :> => (<: for z in x.__value__ :><: expr z :> => <: expr z.__value__ :>,<: endfor :>) <: endfor :>";
$template = Template::Sandbox->new();
$template->add_var( y =>
    {
        one   => { oneone => 'ONEONE', onetwo => 'ONETWO', },
        two   => { twoone => 'TWOAAA', },
        three => { threeone => 'THREEXXX', threetwo => 'THREEYYY' },
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, 'one => (oneone => ONEONE,onetwo => ONETWO,) three => (threeone => THREEXXX,threetwo => THREEYYY,) two => (twoone => TWOAAA,) ', 'nested-for nested-hashes' );

#
#  26: for across undef value.
$syntax = "start <: for x in y :>shouldn't happen <: endfor :>end";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, 'start end',
    'for across undef value' );

#
#  27: for across empty array.
$syntax = "start <: for x in y :>shouldn't happen <: endfor :>end";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
$template->add_var( y => [] );
is( ${$template->run()}, 'start end',
    'for across empty array' );

#
#  28: for across empty hash.
$syntax = "start <: for x in y :>shouldn't happen <: endfor :>end";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
$template->add_var( y => {} );
is( ${$template->run()}, 'start end',
    'for across empty hash' );

#
#  29: loop variable masks template var.
$syntax = "<: expr a :> <: for a in y :><: expr a :> <: endfor :><: expr a :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
$template->add_vars( {
    a => 22,
    y => [ 1, 2, ],
    } );
is( ${$template->run()}, '22 1 2 22',
    'same-name loop-var masks template-var' );

#
#  30: reuse loop variable checking inner masks outer.
$syntax = "<: for x in y :><: for x in z :><: expr x :> <: endfor :><: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
$template->add_vars( {
    y => [ 1, 2, ],
    z => [ 10, 11 ],
    } );
is( ${$template->run()}, '10 11 10 11 ',
    'same-name inner loop-var masks outer loop-var' );

#
#  31: x.__value__[ z ] instead of z.__value__
$syntax = "<: for x in y :><: expr x :> => (<: for z in x.__value__ :><: expr z :> => <: expr x.__value__[ z ] :>,<: endfor :>) <: endfor :>";
$template = Template::Sandbox->new();
$template->add_var( y =>
    {
        one   => { oneone => 'ONEONE', onetwo => 'ONETWO', },
        two   => { twoone => 'TWOAAA', },
        three => { threeone => 'THREEXXX', threetwo => 'THREEYYY' },
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, 'one => (oneone => ONEONE,onetwo => ONETWO,) three => (threeone => THREEXXX,threetwo => THREEYYY,) two => (twoone => TWOAAA,) ',
    'loop-var expr subscript of outer loop-var special-value' );

#
#  32: Ensure op-tree special vars aren't optimized away.
$syntax = "<: for x in 4 :><: expr ( x.__counter__ + 1 ) :><: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '12345',
    'special vars in op-trees are recognised' );

#
#  33: Ensure unary-op special vars aren't optimized away.
$syntax = "<: for x in 4 :><: expr -x.__counter__ :><: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '0-1-2-3-4',
    'special vars in unary-ops are recognised' );

#
#  34: Ensure function argument special vars aren't optimized away.
$syntax = "<: for x in 4 :><: expr defined( x.__counter__ ) :><: endfor :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '11111',
    'special vars in function arguments are recognised' );

#
#  35: Ensure method argument special vars aren't optimized away.
$syntax = "<: for x in 4 :><: expr testob.permitted_method_with_args( x.__counter__ ) :><: endfor :>";
$template = Template::Sandbox->new();
$template->add_var( testob => Template::Sandbox::TestMethodObject->new() );
$template->set_template_string( $syntax );
is( ${$template->run()},
    "args: 0\nargs: 1\nargs: 2\nargs: 3\nargs: 4\n",
    'special vars in method arguments are recognised' );

#
#  36: Ensure expr subscript special vars aren't optimized away.
$syntax = "<: for x in 4 :><: expr x[ y ] :><: endfor :>";
$template = Template::Sandbox->new();
$template->add_var( y => '__counter__' );
$template->set_template_string( $syntax );
is( ${$template->run()}, '01234',
    'inconstant expr-subscript special vars are recognised' );

package Template::Sandbox::TestMethodObject;

sub new
{
    my ( $this ) = @_;
    return( bless {}, $this );
}

sub valid_template_method
{
    my ( $self, $method ) = @_;

    return( 1 ) if $method eq 'permitted_method_with_args';
    return( 0 );
}

sub permitted_method_with_args
{
    my $self = shift;

    return( 'args: ' . join( ', ', @_ ) . "\n" );
}

1;
