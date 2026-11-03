#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which written modifiers the policy reads as changing nothing, and which it leaves alone

=head1 DESCRIPTION

Tables of snippets that must be reported and tables that must not.  Each
reported snippet counts one violation for each modifier that has no effect.

The edges are where each modifier stops having an effect: C</g> on a pattern
that can match only once, C</i> on a pattern with nothing that has a case,
C</m> on a pattern with no C<^> or C<$>, and C</o> on a pattern with nothing
to interpolate.  Interpolation can bring in what the modifier acts on, modifiers
from C<use re> change what the anchors mean, and the modifiers that the house
profile requires are never reported.

=cut

use Test::More;
use Test::Warnings qw{warnings};

use Perl::Critic;

# Loaded so that a syntax error in it is a compile failure here rather than
# Perl::Critic reporting no such policy.  Named as a string below, which is
# what ProhibitUnusedImports cannot see.
use Perl::Critic::Policy::RegularExpressions::ProhibitIneffectiveModifiers;    ## no critic (ProhibitUnusedImports)

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for a
# .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  The anchored long name because -single-policy is a pattern.
my $POLICY = '^Perl::Critic::Policy::RegularExpressions::ProhibitIneffectiveModifiers$';

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
    '/g on a pattern that matches once',
    'caret'                      => [ 1, q{$s =~ s/^\s+//g;} ],
    'backslash A'                => [ 1, q{$s =~ s/\A\s+//g;} ],
    'a match in list context'    => [ 1, q{my @w = $s =~ m/\A(\w+)/g;} ],
    'a match in a loop'          => [ 1, q{while ( $s =~ m/\Afoo/g ) { f() }} ],
    'both ends'                  => [ 1, q{my @w = $s =~ m/^a$/g;} ],
    'backslash z'                => [ 1, q{$s =~ s/\s+\z//g;} ],
    'dollar, not a newline'      => [ 1, q{$s =~ s/x$//g;} ],
    'dollar, a word character'   => [ 1, q{$s =~ s/\w$//g;} ],
    'capital Z'                  => [ 1, q{$s =~ s/,\Z//g;} ],
    'a group before backslash z' => [ 1, q{$s =~ s/(\s+)\z//g;} ],
    'a newline before \z'        => [ 1, q{$s =~ s/\n\z//g;} ],
    'a counted run before \z'    => [ 1, q{$s =~ s/x{2,}\z//g;} ],
    'under /x'                   => [ 1, q{$s =~ s/ ^ \s+ //gx;} ],
    'a split at a separator'     => [ 1, q{$b =~ s/\A([^\n]*)\n//g;} ],
    'the house use re'           => [ 1, q{use re '/aasx'; $s =~ s/^ \s+ //g;} ],
    '\A under /m'                => [ 2, q{$s =~ s/\A\s+//gm;} ],
);

check_table(
    '/g where it can match more than once',
    'unanchored'                   => [ 0, q{$s =~ s/a//g;} ],
    'caret under /m'               => [ 0, q{$s =~ s/^\s+//gm;} ],
    'caret under /m from use re'   => [ 0, q{use re '/m'; $s =~ s/^\s+//g;} ],
    'dollar under /m'              => [ 0, q{$s =~ s/\s+$//gm;} ],
    'several lines of one form'    => [ 0, q{my @k = $t =~ m/^key: .*$/mg;} ],
    'a run that takes the newline' => [ 0, q{$s =~ s/\s+$//g;} ],
    'empty before \z'              => [ 0, q{$s =~ s/b*\z//g;} ],
    'empty before dollar'          => [ 0, q{$s =~ s/$/!/g;} ],
    'a dot under /s before dollar' => [ 0, q{$s =~ s/.$//sg;} ],
    'a newline before dollar'      => [ 0, q{$s =~ s/\n$//g;} ],
    'optional before dollar'       => [ 0, q{$s =~ s/x?$//g;} ],
    'a counted run from zero'      => [ 0, q{$s =~ s/x{0,2}\z//g;} ],
    'alternation in a group'       => [ 0, q{$s =~ s/(?:a|b*)\z//g;} ],
    '/c keeps pos'                 => [ 0, q{$s =~ m/\A\s*/gc;} ],
    'backslash G'                  => [ 0, q{$s =~ m/\Ga/g;} ],
    'alternation'                  => [ 0, q{$s =~ s/\Aa|b//g;} ],
    'an anchor in a group'         => [ 0, q{$s =~ s/(?:\Aa)//g;} ],
    'interpolation'                => [ 0, q{$s =~ s/\A$prefix//g;} ],
);

check_table(
    '/i on a pattern with nothing that has a case',
    'digits'               => [ 1, q{f() if $s =~ m/\d+/i;} ],
    'a class of digits'    => [ 1, q{f() if $s =~ m/[0-9]/i;} ],
    'punctuation'          => [ 1, q{f() if $s =~ m/\.\z/i;} ],
    'a range of no letter' => [ 1, q{f() if $s =~ m/[!-@]/i;} ],
    'a counted quantifier' => [ 1, q{f() if $s =~ m/-{2,}/i;} ],
    'quoted with \Q'       => [ 1, q{f() if $s =~ m/\Q.\E/i;} ],
    'a substitution'       => [ 1, q{$s =~ s/\s+/ /gi;} ],
    'a compiled regex'     => [ 1, q{my $r = qr/\d/i;} ],
);

check_table(
    '/i where a case matters',
    'a letter'              => [ 0, q{f() if $s =~ m/a/i;} ],
    'a range of letters'    => [ 0, q{f() if $s =~ m/[a-z]/i;} ],
    'a range over letters'  => [ 0, q{f() if $s =~ m/[!-~]/i;} ],
    'a letter in hex'       => [ 0, q{f() if $s =~ m/\x41/i;} ],
    'a sharp s'             => [ 0, q{f() if $s =~ m/\x{df}/i;} ],
    'a property'            => [ 0, q{f() if $s =~ m/\p{Lu}/i;} ],
    'a backreference'       => [ 0, q{f() if $s =~ m/(\d)\1/i;} ],
    'interpolation'         => [ 0, q{f() if $s =~ m/$word/i;} ],
    'interpolation and a 1' => [ 0, q{f() if $s =~ m/1$word/i;} ],
    'from use re'           => [ 0, q{use re '/i'; f() if $s =~ m/\d/;} ],
);

check_table(
    '/m on a pattern with no ^ or $',
    'a literal'            => [ 1, q{f() if $s =~ m/foo/m;} ],
    'string anchors'       => [ 1, q{f() if $s =~ m/\Afoo\z/m;} ],
    'capital Z'            => [ 1, q{f() if $s =~ m/foo\Z/m;} ],
    'a negated class'      => [ 1, q{f() if $s =~ m/[^a]/m;} ],
    'a substitution'       => [ 1, q{$s =~ s/\s+/ /gm;} ],
    'a compiled regex'     => [ 1, q{my $r = qr/foo/m;} ],
    'two at once'          => [ 2, q{f() if $s =~ m/\d/im;} ],
    'three at once, and g' => [ 3, q{my @d = $s =~ m/\A\d/gim;} ],
);

check_table(
    '/m where a line anchor is',
    'caret'               => [ 0, q{f() if $s =~ m/^a/m;} ],
    'dollar'              => [ 0, q{f() if $s =~ m/a$/m;} ],
    'in a group'          => [ 0, q{f() if $s =~ m/(?:a|^b)/m;} ],
    'in a lookahead'      => [ 0, q{f() if $s =~ m/a(?=$)/m;} ],
    'interpolation'       => [ 0, q{f() if $s =~ m/$record/m;} ],
    'a compiled regex in' => [ 0, q{my $r = qr/^key: .*$/m; my @l = $t =~ m/$r/g;} ],
    'and /m on it again'  => [ 0, q{my $r = qr/^key: .*$/m; my @l = $t =~ m/$r/mg;} ],
);

check_table(
    '/o on a pattern with nothing to interpolate',
    'a match'          => [ 1, q{f() if $s =~ m/foo/o;} ],
    'a substitution'   => [ 1, q{$s =~ s/foo/$bar/o;} ],
    'a compiled regex' => [ 1, q{my $r = qr/foo/o;} ],
);

check_table(
    '/o and what the house requires',
    'interpolation'           => [ 0, q{f() if $s =~ m/$x/o;} ],
    'interpolation in s///'   => [ 0, q{$s =~ s/$x//o;} ],
    '/s without a dot'        => [ 0, q{f() if $s =~ m/a/s;} ],
    '/x without whitespace'   => [ 0, q{f() if $s =~ m/a/x;} ],
    '/xx'                     => [ 0, q{f() if $s =~ m/a/xx;} ],
    '/aa on ASCII'            => [ 0, q{f() if $s =~ m/a/aa;} ],
    'all three'               => [ 0, q{f() if $s =~ m/a/aasx;} ],
    'no modifiers'            => [ 0, q{f() if $s =~ m/\d/;} ],
    'a transliteration'       => [ 0, q{$s =~ tr/a-z//d;} ],
    'everything that matters' => [ 0, q{my @l = $t =~ m/^key: (.*)$/gimsx;} ],
);

is( scalar( () = warnings { Perl::Critic->new( -profile => q{}, '-single-policy' => $POLICY ) } ), 0, 'nothing warns on construction' );

done_testing();
