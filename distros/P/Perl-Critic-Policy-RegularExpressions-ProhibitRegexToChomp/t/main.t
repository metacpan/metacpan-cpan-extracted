#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which substitutions the policy reads as chomp, and which it leaves alone

=head1 DESCRIPTION

Tables of snippets that must be reported and a table that must not.

A reported substitution has an empty replacement, and a pattern of one newline,
at most one of C<?>, C<*> or C<+>, and an anchor at the end.  The edges are the
spellings of a newline, the quantifiers, the anchors and what C</m> does to
C<$>, and anything else in the pattern or the replacement.

=cut

use Test::More;
use Test::Warnings qw{warnings};

use Perl::Critic;

# Loaded so that a syntax error in it is a compile failure here rather than
# Perl::Critic reporting no such policy.  Named as a string below, which is
# what ProhibitUnusedImports cannot see.
use Perl::Critic::Policy::RegularExpressions::ProhibitRegexToChomp;    ## no critic (ProhibitUnusedImports)

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for a
# .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  The anchored long name because -single-policy is a pattern.
my $POLICY = '^Perl::Critic::Policy::RegularExpressions::ProhibitRegexToChomp$';

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
    'the end of the string',
    'backslash z'         => [ 1, q{$l =~ s/\n\z//;} ],
    'capital Z'           => [ 1, q{$l =~ s/\n\Z//;} ],
    'dollar'              => [ 1, q{$l =~ s/\n$//;} ],
    '/m with \z'          => [ 1, q{$l =~ s/\n\z//m;} ],
    'against the topic'   => [ 1, q{s/\n\z// for @lines;} ],
    'other delimiters'    => [ 1, q{$l =~ s{\n\z}{};} ],
    'a copy, with /r'     => [ 1, q{my $m = $p{message} =~ s/\n+\z//r;} ],
    '/g, which is moot'   => [ 1, q{$l =~ s/\n\z//g;} ],
    'under /x'            => [ 1, q{$l =~ s/ \n \z //x;} ],
    'under /x, commented' => [ 1, qq{\$l =~ s/\\n # the newline\n \\z//x;} ],
);

check_table(
    'spellings of a newline',
    'hex'                 => [ 1, q{$l =~ s/\x0a\z//;} ],
    'hex in braces'       => [ 1, q{$l =~ s/\x{0A}\z//;} ],
    'octal'               => [ 1, q{$l =~ s/\012\z//;} ],
    'a class of one'      => [ 1, q{$l =~ s/[\n]\z//;} ],
    'a class, quantified' => [ 1, q{$l =~ s/[\n]*\Z//;} ],
);

check_table(
    'quantifiers',
    'plus'       => [ 1, q{$l =~ s/\n+\z//;} ],
    'star'       => [ 1, q{$l =~ s/\n*\z//;} ],
    'question'   => [ 1, q{$l =~ s/\n?\z//;} ],
    'lazy'       => [ 1, q{$l =~ s/\n+?\z//;} ],
    'possessive' => [ 1, q{$l =~ s/\n++\z//;} ],
);

check_table(
    'not a chomp',
    'another character'      => [ 0, q{$l =~ s/x\z//;} ],
    'a carriage return'      => [ 0, q{$l =~ s/\r\z//;} ],
    'a class of another'     => [ 0, q{$l =~ s/[\r]\z//;} ],
    'a carriage return too'  => [ 0, q{$l =~ s/\r?\n\z//;} ],
    'any line ending'        => [ 0, q{$l =~ s/\R\z//;} ],
    'trailing whitespace'    => [ 0, q{$l =~ s/\s+\z//;} ],
    'a class of two'         => [ 0, q{$l =~ s/[\r\n]+\z//;} ],
    'a negated class'        => [ 0, q{$l =~ s/[^\n]\z//;} ],
    'unanchored'             => [ 0, q{$l =~ s/\n//;} ],
    'anchored at the start'  => [ 0, q{$l =~ s/\A\n//;} ],
    'two newlines'           => [ 0, q{$l =~ s/\n\n\z//;} ],
    'a counted quantifier'   => [ 0, q{$l =~ s/\n{2,}\z//;} ],
    '/m with dollar'         => [ 0, q{$l =~ s/\n$//m;} ],
    'a replacement'          => [ 0, q{$l =~ s/\n\z/;/;} ],
    'a replacement under /e' => [ 0, q{$l =~ s/\n\z/f()/e;} ],
    'interpolation'          => [ 0, q{$l =~ s/$eol\z//;} ],
    'something else first'   => [ 0, q{$l =~ s/x\n\z//;} ],
    'a match'                => [ 0, q{f() if $l =~ m/\n\z/;} ],
    'a transliteration'      => [ 0, q{$l =~ tr/\n//d;} ],
    'chomp itself'           => [ 0, q{chomp $l;} ],
);

is( scalar( () = warnings { Perl::Critic->new( -profile => q{}, '-single-policy' => $POLICY ) } ), 0, 'nothing warns on construction' );

done_testing();
