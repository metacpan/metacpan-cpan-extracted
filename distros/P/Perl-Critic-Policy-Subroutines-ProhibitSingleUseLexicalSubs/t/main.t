#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which lexical subs the policy reads as used in one place, and which
it leaves alone

=head1 DESCRIPTION

Tables of snippets that must be reported and a table that must not.

A reported sub is declared with C<my> or C<state>, as C<my sub NAME> or as
C<my $NAME = sub>, and the rest of its block uses it exactly once.  The edges
are the ways of using it (a call, a reference, a method call through a scalar,
a callback), zero and two uses, recursion, a name declared again, and the
words that are spelled like the name and are something else.

=cut

use Test::More;

use Perl::Critic;

# Loaded so that a syntax error in it is a compile failure here rather than
# Perl::Critic reporting no such policy.  Named as a string below, which is
# what ProhibitUnusedImports cannot see.
use Perl::Critic::Policy::Subroutines::ProhibitSingleUseLexicalSubs;    ## no critic (ProhibitUnusedImports)

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for a
# .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  The anchored long name because -single-policy is a pattern.
my $POLICY = '^Perl::Critic::Policy::Subroutines::ProhibitSingleUseLexicalSubs$';

my $critic = Perl::Critic->new( -profile => q{}, '-single-policy' => $POLICY, -severity => 1 );

my $check_table = sub {
    my ( $label, %cases ) = @_;
    foreach my $case ( sort keys %cases ) {
        my ( $expected, $source ) = @{ $cases{$case} };
        is( scalar $critic->critique( \$source ), $expected, "$label: $case" ) or diag $source;
    }
    return;
};

$check_table->(
    'a named lexical sub used once',
    'called'                => [ 1, q{my sub helper { return 1 } helper();} ],
    'called without parens' => [ 1, q{my sub helper { return 1 } my $x = helper;} ],
    'a state sub'           => [ 1, q{state sub helper { return 1 } helper();} ],
    'taken as a reference'  => [ 1, q{my sub helper { return 1 } my $ref = \&helper;} ],
    'called with an &'      => [ 1, q{my sub helper { return 1 } &helper;} ],
    'in a nested block'     => [ 1, q{my sub helper { return 1 } if ($x) { helper() }} ],
    'inside a sub'          => [ 1, q{sub outer { my sub helper { return 1 } return helper() }} ],
);

$check_table->(
    'a sub in a scalar used once',
    'called'           => [ 1, q{my $helper = sub { return 1 }; $helper->();} ],
    'called with an &' => [ 1, q{my $helper = sub { return 1 }; &$helper();} ],
    'as a method'      => [ 1, q{my $helper = sub { return 1 }; $self->$helper(1);} ],
    'as a callback'    => [ 1, q{my $wanted = sub { return 1 }; find( { wanted => $wanted }, $dir );} ],
    'as a sort block'  => [ 1, q{my $by = sub { $a <=> $b }; my @s = sort $by @x;} ],
    'a state variable' => [ 1, q{state $helper = sub { return 1 }; $helper->();} ],
);

$check_table->(
    'allowed',
    'used twice'                    => [ 0, q{my sub helper { return 1 } helper(); helper();} ],
    'a scalar used twice'           => [ 0, q{my $helper = sub { return 1 }; $helper->(); $helper->();} ],
    'used by two subs'              => [ 0, q{my sub helper { return 1 } sub one { helper() } sub two { helper() }} ],
    'not used at all'               => [ 0, q{my sub helper { return 1 }} ],
    'recursive'                     => [ 0, q{my sub walk { return walk(@_) } walk($root);} ],
    'a package sub'                 => [ 0, q{sub helper { return 1 } helper();} ],
    'a package variable'            => [ 0, q{our $helper = sub { return 1 }; $helper->();} ],
    'a scalar that is not a sub'    => [ 0, q{my $x = 1; print $x;} ],
    'an anonymous sub called there' => [ 0, q{my $x = sub { return 1 }->(); print $x;} ],
    'two scalars in one statement'  => [ 0, q{my ( $x, $y ) = ( sub { 1 }, 2 ); $x->();} ],
    'used before it is declared'    => [ 0, q{helper(); my sub helper { return 1 }} ],
    'declared again later'          => [ 0, q{my sub helper { return 1 } helper(); { my sub helper { return 2 } helper(); helper() }} ],
    'a scalar declared again'       => [ 0, q{my $h = sub { 1 }; $h->(); { my $h = sub { 2 }; $h->(); $h->() }} ],
);

$check_table->(
    'the same spelling, another thing',
    'a method'                => [ 1, q{my sub helper { return 1 } helper(); $obj->helper();} ],
    'a hash key'              => [ 1, q{my sub helper { return 1 } helper(); $h{helper} = 1;} ],
    'the left of a fat comma' => [ 1, q{my sub helper { return 1 } helper(); my %h = ( helper => 1 );} ],
    'another scalar'          => [ 1, q{my $helper = sub { return 1 }; $helper->(); my @helper = (1);} ],
);

done_testing;
