#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which matches the policy reads as a test of equality, and which it leaves alone

=head1 DESCRIPTION

Tables of snippets that must be reported and a table that must not.

A reported match has a start anchor, C<\z>, and between them either literal
text or one plain group of literal alternatives.  The edges are the anchors,
what C</m> does to C<^>, the modifiers that exempt a pattern, the kinds of
group, and anything in the pattern that is not literal text.

=cut

use Test::More;
use Test::Warnings qw{warnings};

use Perl::Critic;

# Loaded so that a syntax error in it is a compile failure here rather than
# Perl::Critic reporting no such policy.  Named as a string below, which is
# what ProhibitUnusedImports cannot see.
use Perl::Critic::Policy::RegularExpressions::ProhibitRegexForStringEquality;    ## no critic (ProhibitUnusedImports)

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for a
# .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  The anchored long name because -single-policy is a pattern.
my $POLICY = '^Perl::Critic::Policy::RegularExpressions::ProhibitRegexForStringEquality$';

my $critic = Perl::Critic->new( -profile => q{}, '-single-policy' => $POLICY, -severity => 1 );

sub check_table {
    my ( $label, %cases ) = @_;
    foreach my $case ( sort keys %cases ) {
        my ( $expected, $source ) = @{ $cases{$case} };
        is( scalar $critic->critique( \$source ), $expected, "$label: $case" ) or diag $source;
    }
    return;
}

# The description of the one violation in $source, which names what to use.
sub advice_for {
    my ($source)    = @_;
    my ($violation) = $critic->critique( \$source );
    return $violation ? $violation->explanation() : q{};
}

check_table(
    'literal text, which is eq',
    'backslash A'          => [ 1, q{f() if $s =~ m/\Afoo\z/;} ],
    'caret'                => [ 1, q{f() if $s =~ m/^foo\z/;} ],
    'negated'              => [ 1, q{f() if $s !~ m/\Afoo\z/;} ],
    'no m'                 => [ 1, q{f() if $s =~ /\Afoo\z/;} ],
    'other delimiters'     => [ 1, q{f() if $s =~ m{\Afoo\z};} ],
    'an escaped character' => [ 1, q{f() if $s =~ m/\Afoo\.bar\z/;} ],
    'one character'        => [ 1, q{f() if $s =~ m/\Ax\z/;} ],
    'against the topic'    => [ 1, q{f() if m/\Afoo\z/;} ],
    'in a grep block'      => [ 1, q{my @x = grep { m/\Afoo\z/ } @names;} ],
    'under /x'             => [ 1, q{f() if $s =~ m/\A foo \z/x;} ],
    'under /s'             => [ 1, q{f() if $s =~ m/\Afoo\z/s;} ],
    '/m with backslash A'  => [ 1, q{f() if $s =~ m/\Afoo\z/m;} ],
    'a group of one'       => [ 1, q{f() if $s =~ m/\A(?:foo)\z/;} ],
);

check_table(
    'literal alternatives, which is any',
    'two'               => [ 1, q{f() if $s =~ m/\A(?:Skill|Read)\z/;} ],
    'three, with caret' => [ 1, q{f() if $s =~ m/^(?:a|b|c)\z/;} ],
    'negated'           => [ 1, q{f() if $s !~ m/\A(?:a|b)\z/;} ],
    'under /x'          => [ 1, q{f() if $s =~ m/\A (?: a | b ) \z/x;} ],
);

check_table(
    'not a test of equality',
    'dollar at the end'           => [ 0, q{f() if $s =~ m/\Afoo$/;} ],
    'capital Z at the end'        => [ 0, q{f() if $s =~ m/\Afoo\Z/;} ],
    'no end anchor'               => [ 0, q{f() if $s =~ m/\Afoo/;} ],
    'no start anchor'             => [ 0, q{f() if $s =~ m/foo\z/;} ],
    'unanchored'                  => [ 0, q{f() if $s =~ m/foo/;} ],
    'caret under /m'              => [ 0, q{f() if $s =~ m/^foo\z/m;} ],
    '/i'                          => [ 0, q{f() if $s =~ m/\Afoo\z/i;} ],
    '/g'                          => [ 0, q{f() while $s =~ m/\Afoo\z/g;} ],
    'use re /i in scope'          => [ 0, qq{use re '/i';\nf() if \$s =~ m/\\Afoo\\z/;} ],
    'a capture'                   => [ 0, q{f() if $s =~ m/\A(foo|bar)\z/;} ],
    'a group with modifiers'      => [ 0, q{f() if $s =~ m/\A(?i:a|b)\z/;} ],
    'a group that resets them'    => [ 0, q{f() if $s =~ m/\A(?^:a|b)\z/;} ],
    'alternation outside a group' => [ 0, q{f() if $s =~ m/\Afoo|bar\z/;} ],
    'an empty alternative'        => [ 0, q{f() if $s =~ m/\A(?:a|)\z/;} ],
    'text beside the group'       => [ 0, q{f() if $s =~ m/\Ax(?:a|b)\z/;} ],
    'two groups'                  => [ 0, q{f() if $s =~ m/\A(?:a)(?:b)\z/;} ],
    'a quantifier'                => [ 0, q{f() if $s =~ m/\Afo+\z/;} ],
    'a quantified group'          => [ 0, q{f() if $s =~ m/\A(?:a|b)+\z/;} ],
    'a character class'           => [ 0, q{f() if $s =~ m/\A[ab]\z/;} ],
    'a dot'                       => [ 0, q{f() if $s =~ m/\Af.o\z/;} ],
    'interpolation'               => [ 0, q{f() if $s =~ m/\A$foo\z/;} ],
    'nothing between the anchors' => [ 0, q{f() if $s =~ m/\A\z/;} ],
    'a substitution'              => [ 0, q{$s =~ s/\Afoo\z/bar/;} ],
    'a compiled regex'            => [ 0, q{my $rx = qr/\Afoo\z/;} ],
    'the pattern of split'        => [ 0, q{my @x = split m/\Afoo\z/, $s;} ],
    'split with parentheses'      => [ 0, q{my @x = split( m/\Afoo\z/, $s );} ],
    'CORE::split'                 => [ 0, q{my @x = CORE::split( m/\Afoo\z/, $s );} ],
    'eq itself'                   => [ 0, q{f() if $s eq 'foo';} ],
);

like( advice_for(q{f() if $s =~ m/\Afoo\z/;}),     qr/\AUse[ ]eq/xs,              'literal text names eq' );
like( advice_for(q{f() if $s =~ m/\A(?:a|b)\z/;}), qr/\AUse[ ]List::Util::any/xs, 'alternatives name any' );

is( scalar( () = warnings { Perl::Critic->new( -profile => q{}, '-single-policy' => $POLICY ) } ), 0, 'nothing warns on construction' );

done_testing();
