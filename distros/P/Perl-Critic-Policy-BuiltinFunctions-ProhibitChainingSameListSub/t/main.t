#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which chains of list functions the policy reports, and which it leaves alone

=head1 DESCRIPTION

Tables of snippets that must be reported and a table that must not.

A chain is a list function whose list starts with a call to the same function.
The edges are how the list is found -- after a block, after the first comma of
the expression form, inside parentheses -- and what does not count as the same
function: a different one, one later in the list, one nested in the block, and
a method of the same name.

=cut

use Test::More;
use Test::Warnings qw{warnings};

use Perl::Critic;

# Loaded so that a syntax error in it is a compile failure here rather than
# Perl::Critic reporting no such policy.  Named as a string below, which is
# what ProhibitUnusedImports cannot see.
use Perl::Critic::Policy::BuiltinFunctions::ProhibitChainingSameListSub;    ## no critic (ProhibitUnusedImports)

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for a
# .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  The anchored long name because -single-policy is a pattern.
my $POLICY = '^Perl::Critic::Policy::BuiltinFunctions::ProhibitChainingSameListSub$';

my $critic = Perl::Critic->new( -profile => q{}, '-single-policy' => $POLICY, -severity => 1 );

sub check_table {
    my ( $label, %cases ) = @_;
    foreach my $case ( sort keys %cases ) {
        my ( $expected, $source ) = @{ $cases{$case} };
        is( scalar $critic->critique( \$source ), $expected, "$label: $case" ) or diag $source;
    }
    return;
}

check_table(
    'a chain',
    'map into map'                => [ 1, q{my @n = map { lc } map { $_->name } @users;} ],
    'grep into grep'              => [ 1, q{my @l = grep { !$_->deleted } grep { $_->active } @rows;} ],
    'sort into sort'              => [ 1, q{my @s = sort { $a <=> $b } sort @x;} ],
    'sort with no block'          => [ 1, q{my @s = sort sort @x;} ],
    'any into any'                => [ 1, q{my $t = any { a($_) } any { b($_) } @x;} ],
    'first into first'            => [ 1, q{my $f = first { a($_) } first { b($_) } @x;} ],
    'qualified, then bare'        => [ 1, q{my $f = List::Util::first { a($_) } first { b($_) } @x;} ],
    'bare, then qualified'        => [ 1, q{my $f = first { a($_) } List::Util::first { b($_) } @x;} ],
    'expression form'             => [ 1, q{my @n = map lc, map uc, @x;} ],
    'expression form with a call' => [ 1, q{my @n = map f($_), map g($_), @x;} ],
    'parenthesised'               => [ 1, q{my @n = map( { f($_) } map { g($_) } @x );} ],
    'inner parenthesised'         => [ 1, q{my @n = map { f($_) } map( { g($_) } @x );} ],
    'three deep'                  => [ 2, q{my @n = map { f($_) } map { g($_) } map { h($_) } @x;} ],
    'returned'                    => [ 1, q{return map { f($_) } map { g($_) } @x;} ],
    'in a condition'              => [ 1, q{f() if grep { a($_) } grep { b($_) } @x;} ],
    'spread over lines'           => [ 1, qq{my \@n = map {\n  f(\$_)\n}\n  map {\n  g(\$_)\n} \@x;} ],
);

check_table(
    'not a chain',
    'map into grep'             => [ 0, q{my @n = map { f($_) } grep { g($_) } @x;} ],
    'grep into map'             => [ 0, q{my @n = grep { f($_) } map { g($_) } @x;} ],
    'second in a list of lists' => [ 0, q{my @n = map { f($_) } @x, map { g($_) } @y;} ],
    'nested in the block'       => [ 0, q{my @n = map { [ map { f($_) } @$_ ] } @rows;} ],
    'nested in the expression'  => [ 0, q{my @n = map scalar( grep { f($_) } @$_ ), @rows;} ],
    'a method of the same name' => [ 0, q{my $r = $obj->map( sub { 1 } )->map( sub { 2 } );} ],
    'a hash key'                => [ 0, q{my $v = $h{map} + map { f($_) } @x;} ],
    'a fat-comma key'           => [ 0, q{my %h = ( map => 1, grep => 2 );} ],
    'sort by a named sub'       => [ 0, q{my @s = sort by_name @x;} ],
    'unlisted functions'        => [ 0, q{my @n = reverse reverse @x;} ],
    'one call'                  => [ 0, q{my @n = map { f($_) } @x;} ],
);

# A function named in the configuration is checked; one that is not stays
# unchecked, which the 'unlisted functions' case above already covers.
{
    my $configured = Perl::Critic->new( -profile => \"[BuiltinFunctions::ProhibitChainingSameListSub]\nfunctions = pairmap My::Util::each_item\n", '-single-policy' => $POLICY, -severity => 1 );

    my %cases = (
        'a configured name'                  => [ 1, q{my @p = pairmap { f($a) } pairmap { g($b) } @x;} ],
        'a configured qualified name'        => [ 1, q{My::Util::each_item { f($_) } My::Util::each_item { g($_) } @x;} ],
        'the bare call of a qualified entry' => [ 0, q{each_item { f($_) } each_item { g($_) } @x;} ],
        'the built-in ones still'            => [ 1, q{my @n = map { f($_) } map { g($_) } @x;} ],
    );
    foreach my $case ( sort keys %cases ) {
        my ( $expected, $source ) = @{ $cases{$case} };
        is( scalar $configured->critique( \$source ), $expected, "configured: $case" ) or diag $source;
    }
}

is( scalar( () = warnings { Perl::Critic->new( -profile => q{}, '-single-policy' => $POLICY ) } ), 0, 'nothing warns on construction' );

done_testing();
