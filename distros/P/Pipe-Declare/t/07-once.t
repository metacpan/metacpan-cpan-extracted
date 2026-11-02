#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Pipe::Declare;

# Milestone 5: head expression evaluated exactly once, regardless of step
# count. The topic is stored in a hidden pad temp by the prelude; every
# step reads/writes that temp, so the head's side effects never re-fire.

our $count = 0;
sub seed { $count++; 10 }

sub inc    { $_[0] + 1 }
sub double { $_[0] * 2 }
sub triple { $_[0] * 3 }

# --- one step ------------------------------------------------------------

$count = 0;
{
    my $r = pipe { ( seed() ) |> double };
    is( $count, 1, 'head with side effect: 1 call for 1 step' );
    is( $r, 20,    '...and the value is correct' );
}

# --- many steps ----------------------------------------------------------

$count = 0;
{
    my $r = pipe {
        ( seed() )
            |> inc
            |> double
            |> triple
            |> inc
            |> inc
    };
    is( $count, 1, 'head with side effect: still 1 call for 5 steps' );
    is( $r, ((10 + 1) * 2 * 3) + 1 + 1, '...and the value is correct' );
}

# --- with all step kinds together (method, deref, block) -----------------

package SideEffect;
sub new {
    my ($class, $n) = @_;
    $main::count++;
    bless { n => $n, list => [1,2,3] }, $class;
}
sub n    { $_[0]->{n}    }
sub list { $_[0]->{list} }
package main;

$count = 0;
{
    my $r = pipe {
        ( SideEffect->new(7) )
            |> ->list
            |> map  { $_ + 1 }
            |> grep { $_ > 1 }
    };
    is( $count, 1, 'head SideEffect->new(7): 1 call across method+block steps' );
    is_deeply( $r, [2, 3, 4], '...and the value is correct' );
}

# --- tap chain ----------------------------------------------------------

$count = 0;
{
    my $r = pipe { ( seed() ) |> tap { } |> tap { } |> tap { } };
    is( $count, 1, 'head: still 1 call with three taps' );
    is( $r, 10, 'topic passed through tap unchanged' );
}

# --- $cv step also reads the same pad temp -------------------------------

$count = 0;
{
    my $doubler = \&double;
    my $r = pipe { ( seed() ) |> $doubler |> $doubler };
    is( $count, 1, 'head: still 1 call through two $cv steps' );
    is( $r, 40, '10 * 2 * 2 = 40' );
}

done_testing;
