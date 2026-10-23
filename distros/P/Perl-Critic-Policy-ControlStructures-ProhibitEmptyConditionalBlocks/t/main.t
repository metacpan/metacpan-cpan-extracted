#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which conditional blocks the policy reads as empty, and which it leaves alone

=head1 DESCRIPTION

Tables of snippets that must be reported, with how many times, and a table that
must not.

A block is empty when it holds no statement.  The edges are what
can sit in a block without being a statement -- blank lines, comments, a lone
semicolon -- each keyword of a chain, and the blocks that are not conditionals.

=cut

use Test::More;
use Test::Warnings qw{warnings};

use Perl::Critic;

# Loaded so that a syntax error in it is a compile failure here rather than
# Perl::Critic reporting no such policy.  Named as a string below, which is
# what ProhibitUnusedImports cannot see.
use Perl::Critic::Policy::ControlStructures::ProhibitEmptyConditionalBlocks;    ## no critic (ProhibitUnusedImports)

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for a
# .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  The anchored long name because -single-policy is a pattern.
my $POLICY = '^Perl::Critic::Policy::ControlStructures::ProhibitEmptyConditionalBlocks$';

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
    'what an empty block holds',
    'nothing'              => [ 1, q{if ($x) {}} ],
    'blank lines'          => [ 1, qq{if (\$x) {\n\n}} ],
    'a comment'            => [ 1, qq{if (\$x) {\n    # nothing to do\n}} ],
    'a lone semicolon'     => [ 1, q{if ($x) { ; }} ],
    'POD'                  => [ 1, qq{if (\$x) {\n\n=pod\n\nnothing\n\n=cut\n\n}} ],
    'a statement'          => [ 0, q{if ($x) { f() }} ],
    'a statement, no semi' => [ 0, q{if ($x) { 1 }} ],
    'a nested empty block' => [ 1, q{if ($x) { if ($y) {} }} ],
    'a bare block'         => [ 0, q{if ($x) { { f() } }} ],
);

check_table(
    'each keyword of a chain',
    'unless'            => [ 1, q{unless ($x) {}} ],
    'elsif'             => [ 1, q{if ($x) { f() } elsif ($y) {} else { g() }} ],
    'else'              => [ 1, q{if ($x) { f() } else {}} ],
    'unless with else'  => [ 1, q{unless ($x) { f() } else {}} ],
    'every one of them' => [ 3, q{if ($x) {} elsif ($y) {} else {}} ],
    'a chain with none' => [ 0, q{if ($x) { f() } elsif ($y) { g() } else { h() }} ],
);

check_table(
    'not a conditional',
    'a postfix if'       => [ 0, q{f() if $x;} ],
    'a while loop'       => [ 0, q{while ( waitpid( -1, 1 ) > 0 ) {}} ],
    'an until loop'      => [ 0, q{until ($x) {}} ],
    'a foreach loop'     => [ 0, q{foreach my $y (@x) {}} ],
    'a C-style for loop' => [ 0, q{for ( my $i = 0; $i < 3; $i++ ) {}} ],
    'a sub'              => [ 0, q{sub noop {}} ],
    'an anonymous sub'   => [ 0, q{my $noop = sub {};} ],
    'a bare block'       => [ 0, q{{}} ],
    'an empty hash'      => [ 0, q{my $h = {};} ],
    'a ternary'          => [ 0, q{my $y = $x ? 1 : 0;} ],
);

my @violations = $critic->critique( \q{if ($x) {} elsif ($y) { f() } else {}} );
is_deeply( [ map { $_->description } @violations ],   [ 'Empty if block', 'Empty else block' ], 'each violation names the keyword of its block' );
is_deeply( [ map { $_->column_number } @violations ], [ 1,                31 ],                 'and points at that keyword' );

is( scalar( () = warnings { Perl::Critic->new( -profile => q{}, '-single-policy' => $POLICY ) } ), 0, 'nothing warns on construction' );

done_testing();
