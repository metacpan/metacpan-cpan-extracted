#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Pipe::Declare;

# Milestone 3 / method and deref steps: the topic is the invocant or the
# aggregate, depending on shape.

# --- a tiny class --------------------------------------------------------

package Counter;
sub new   { my ($c, $n) = @_; bless { n => $n // 0 }, $c }
sub value { $_[0]->{n} }
sub inc   { $_[0]->{n}++; $_[0] }
sub add   { my ($s, $x) = @_; $s->{n} += $x; $s }
sub mul   { my ($s, $x) = @_; $s->{n} *= $x; $s }
package main;

# --- ->method (nullary) ---------------------------------------------------

{
    my $c = Counter->new(10);
    is( (pipe { $c |> ->value }), 10, '->value reads invocant attribute' );
}

# --- ->method(args) -------------------------------------------------------

{
    my $c = Counter->new(0);
    my $r = pipe { $c |> ->add(5) |> ->mul(3) |> ->value };
    is( $r, 15, '->add(5) |> ->mul(3) |> ->value : chained mutators + accessor' );
}

# --- chains of methods, returning $self -----------------------------------

{
    my $c = Counter->new(2);
    is( (pipe { $c |> ->inc |> ->inc |> ->inc |> ->value }),
        5,
        'chained nullary methods returning $self' );
}

# --- ->{key} hash deref ---------------------------------------------------

{
    my $h = { name => 'foo', age => 42 };
    is( (pipe { $h |> ->{name} }), 'foo', '->{key} bareword key' );
    is( (pipe { $h |> ->{'age'} }), 42,   '->{key} string-literal key' );
}

# --- ->[idx] array deref --------------------------------------------------

{
    my $a = [ 'zero', 'one', 'two', 'three' ];
    is( (pipe { $a |> ->[0] }),       'zero',  '->[0]' );
    is( (pipe { $a |> ->[2] }),       'two',   '->[2]' );
    is( (pipe { $a |> ->[1 + 1] }),   'two',   '->[expr]' );
}

# --- deeply chained derefs ------------------------------------------------

{
    my $deep = {
        users => [
            { name => 'a', tags => [qw/x y z/] },
            { name => 'b', tags => [qw/p q/]   },
        ],
    };
    is( (pipe { $deep |> ->{users} |> ->[1] |> ->{tags} |> ->[0] }),
        'p',
        'four-step deref chain through nested data' );
}

# --- method then deref then method ---------------------------------------

package Bag;
sub new   { bless { items => [@_[1..$#_]] }, $_[0] }
sub items { $_[0]->{items} }
package main;

{
    my $bag = Bag->new(qw/alpha beta gamma/);
    is( (pipe { $bag |> ->items |> ->[1] }),
        'beta',
        'method -> deref chain' );
}

# --- mixed bareword + method + deref -------------------------------------

sub wrap { "[$_[0]]" }
{
    my $h = { tag => 'ok' };
    is( (pipe { $h |> ->{tag} |> wrap }),
        '[ok]',
        '->{key} feeds into bareword step' );
}

done_testing;
