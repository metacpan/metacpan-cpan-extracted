#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which patterns the policy reads as taking the text before a separator, and which it leaves alone

=head1 DESCRIPTION

Tables of snippets that must be reported and a table that must not.

A reported regex is a match, or a substitution with an empty replacement, whose
pattern is an anchor at the start of the string, everything before a literal
separator, with or without one capture around it, and that separator.  The edges are the two
spellings of "everything before" (a negated class and a lazy dot), what C<.>
means without C</s>, the spellings of the separator, the anchors and what C</m>
does to C<^>, modifiers turned on by C<use re>, and anything else in the
pattern or the replacement.

=cut

use Test::More;
use Test::Warnings qw{warnings};

use Perl::Critic;

# Loaded so that a syntax error in it is a compile failure here rather than
# Perl::Critic reporting no such policy.  Named as a string below, which is
# what ProhibitUnusedImports cannot see.
use Perl::Critic::Policy::RegularExpressions::ProhibitRegexToSplitAtDelimiter;    ## no critic (ProhibitUnusedImports)

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for a
# .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  The anchored long name because -single-policy is a pattern.
my $POLICY = '^Perl::Critic::Policy::RegularExpressions::ProhibitRegexToSplitAtDelimiter$';

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
    'a negated class of the separator',
    'a substitution'          => [ 1, q{while ( $b =~ s/\A([^\n]*)\n// ) { take($1) }} ],
    'one or more'             => [ 1, q{$b =~ s/\A([^\n]+)\n//;} ],
    'a match'                 => [ 1, q{my ($k) = $l =~ m/\A([^=]*)=/;} ],
    'caret'                   => [ 1, q{my ($k) = $l =~ m/^([^:]*):/;} ],
    'bare slashes'            => [ 1, q{my ($k) = $l =~ /\A([^:]*):/;} ],
    'other delimiters'        => [ 1, q{$b =~ s{\A([^\n]*)\n}{};} ],
    'against the topic'       => [ 1, q{my @k = map { m/\A([^:]*):/ ? $1 : () } @lines;} ],
    'a copy, with /r'         => [ 1, q{my $rest = $b =~ s/\A([^\n]*)\n//r;} ],
    'possessive'              => [ 1, q{my ($k) = $l =~ m/\A([^:]*+):/;} ],
    'lazy'                    => [ 1, q{my ($k) = $l =~ m/\A([^:]*?):/;} ],
    'a named capture'         => [ 1, q{f($+{k}) if $l =~ m/\A(?<k>[^:]*):/;} ],
    '/m with \A'              => [ 1, q{my ($k) = $l =~ m/\A([^:]*):/m;} ],
    'under /x'                => [ 1, q{my ($k) = $l =~ m/\A ( [^:]* ) : /x;} ],
    'under /x with a comment' => [ 1, qq{my (\$k) = \$l =~ m/\\A ([^:]*) # the key\n : /x;} ],
    'not a newline'           => [ 1, q{my ($k) = $l =~ m/\A([^\t]*)\t/;} ],
);

check_table(
    'a lazy dot',
    'a newline, without /s'      => [ 1, q{my ($l) = $b =~ m/\A(.*?)\n/;} ],
    'a newline, under /s'        => [ 1, q{my ($l) = $b =~ m/\A(.*?)\n/s;} ],
    'greedy before a newline'    => [ 1, q{my ($l) = $b =~ m/\A(.*)\n/;} ],
    'one or more'                => [ 1, q{my ($k) = $l =~ m/\A(.+?):/s;} ],
    'a string separator'         => [ 1, q{my ($k) = $l =~ m/\A(.*?)--/s;} ],
    'a string with a space'      => [ 1, q{my ($k) = $l =~ m/\A(.*?), /s;} ],
    'quoted with \Q'             => [ 1, q{my ($k) = $l =~ m/\A(.*?)\Q-.\E/s;} ],
    '/s from use re'             => [ 1, q{use re '/s'; my ($k) = $l =~ m/\A(.*?):/;} ],
    'the house modifiers'        => [ 1, q{use re '/aasx'; my ($k) = $l =~ m/\A (.*?) :: /;} ],
    '\N, which is not a newline' => [ 1, q{my ($l) = $b =~ m/\A(\N*)\n/;} ],
);

check_table(
    'spellings of the separator',
    'hex'                      => [ 1, q{$b =~ s/\A([^\n]*)\x0a//;} ],
    'hex in braces'            => [ 1, q{$b =~ s/\A([^\x{0A}]*)\n//;} ],
    'octal'                    => [ 1, q{$b =~ s/\A([^\n]*)\012//;} ],
    'a class of one'           => [ 1, q{$b =~ s/\A([^\n]*)[\n]//;} ],
    'an escaped metacharacter' => [ 1, q{my ($h) = $n =~ m/\A([^.]*)\./;} ],
    'escaped in the class too' => [ 1, q{my ($h) = $n =~ m/\A([^\.]*)\./;} ],
    'a slash'                  => [ 1, q{my ($h) = $p =~ m{\A([^/]*)/};} ],
);

check_table(
    'not a split at a separator',
    'a dot without /s'               => [ 0, q{my ($k) = $l =~ m/\A(.*?):/;} ],
    'a dot, /s turned off'           => [ 0, q{use re '/s'; no re '/s'; my ($k) = $l =~ m/\A(.*?):/;} ],
    'greedy, which is the last one'  => [ 0, q{my ($k) = $l =~ m/\A(.*):/s;} ],
    'greedy under /s before newline' => [ 0, q{my ($l) = $b =~ m/\A(.*)\n/s;} ],
    '\N before something else'       => [ 0, q{my ($k) = $l =~ m/\A(\N*?):/;} ],
    'caret under /m'                 => [ 0, q{my ($k) = $l =~ m/^([^:]*):/m;} ],
    'caret under /m from use re'     => [ 0, q{use re '/m'; my ($k) = $l =~ m/^([^:]*):/;} ],
    'unanchored'                     => [ 0, q{my ($k) = $l =~ m/([^:]*):/;} ],
    'anchored after the last match'  => [ 0, q{my ($k) = $l =~ m/\G([^:]*):/gc;} ],
    '/g on a match'                  => [ 0, q{my @k = $l =~ m/\A([^:]*):/g;} ],
    '/g on a substitution'           => [ 0, q{$b =~ s/\A([^\n]*)\n//g;} ],
    '/i'                             => [ 0, q{my ($k) = $l =~ m/\A([^x]*)x/i;} ],
    'a class of several'             => [ 0, q{my ($k) = $l =~ m/\A([^:;]*)[:;]/;} ],
    'a negated class of several'     => [ 0, q{my ($k) = $l =~ m/\A([^ab]*)ab/;} ],
    'a class of one, before two'     => [ 0, q{my ($k) = $l =~ m/\A([^a]*)ab/;} ],
    'the class is not the separator' => [ 0, q{my ($k) = $l =~ m/\A([^:]*);/;} ],
    'whitespace'                     => [ 0, q{my ($k) = $l =~ m/\A(.*?)\s/s;} ],
    'any line ending'                => [ 0, q{my ($l) = $b =~ m/\A(.*?)\R/s;} ],
    'alternation'                    => [ 0, q{my ($k) = $l =~ m/\A(.*?)(?:,|;)/s;} ],
    'interpolation'                  => [ 0, q{my ($k) = $l =~ m/\A(.*?)$sep/s;} ],
    'interpolation in the class'     => [ 0, q{my ($k) = $l =~ m/\A([^$sep]*)$sep/;} ],
    'a quantified separator'         => [ 0, q{$b =~ s/\A([^\n]*)\n+//;} ],
    'an optional separator'          => [ 0, q{$b =~ s/\A([^\n]*)\n?//;} ],
    'a counted capture'              => [ 0, q{my ($k) = $l =~ m/\A([^:]{2,}):/;} ],
    'a narrower capture'             => [ 0, q{my ($k) = $l =~ m/\A(\w*):/;} ],
    'a capture of one'               => [ 0, q{my ($k) = $l =~ m/\A([^:]):/;} ],
    'two captures'                   => [ 0, q{my ($k, $v) = $l =~ m/\A([^:]*):(.*)\z/s;} ],
    'something after the separator'  => [ 0, q{$l =~ s/\A([^:]*):\s*//;} ],
    'anchored at the end too'        => [ 0, q{my ($l) = $b =~ m/\A([^\n]*)\n\z/;} ],
    'no separator'                   => [ 0, q{my ($k) = $l =~ m/\A([^:]*)/;} ],
    'a replacement'                  => [ 0, q{$b =~ s/\A([^\n]*)\n/$1 /;} ],
    'a compiled regex'               => [ 0, q{my $rx = qr/\A([^\n]*)\n/;} ],
    'a split'                        => [ 0, q{my ($k) = split /:/, $l, 2;} ],
    'index itself'                   => [ 0, q{my $k = substr $l, 0, index $l, ':';} ],
);

check_table(
    'without a capture',
    'a substitution'           => [ 1, q{$b =~ s/\A[^\n]*\n//;} ],
    'one or more'              => [ 1, q{$b =~ s/\A[^\n]+\n//;} ],
    'possessive'               => [ 1, q{$b =~ s/\A[^\n]*+\n//;} ],
    'caret'                    => [ 1, q{$b =~ s/^[^\n]*\n//;} ],
    'a copy, with /r'          => [ 1, q{my $rest = $b =~ s/\A[^\n]*\n//r;} ],
    'a lazy dot under /s'      => [ 1, q{$l =~ s/\A.*?--//s;} ],
    'a dot before a newline'   => [ 1, q{$b =~ s/\A.*\n//;} ],
    '\N before a newline'      => [ 1, q{$b =~ s/\A\N*\n//;} ],
    '/s from use re'           => [ 1, q{use re '/s'; $l =~ s/\A.*?://;} ],
    'hex'                      => [ 1, q{$b =~ s/\A[^\n]*\x0a//;} ],
    'a class of one'           => [ 1, q{$b =~ s/\A[^\n]*[\n]//;} ],
    'an escaped metacharacter' => [ 1, q{$n =~ s/\A[^.]*\.//;} ],
    'quoted with \Q'           => [ 1, q{$l =~ s/\A.*?\Q-.\E//s;} ],
    'under /x'                 => [ 1, q{$l =~ s/\A [^:]* : //x;} ],
    'a match'                  => [ 1, q{f() if $l =~ m/\A[^:]*:/;} ],
    'a match with a lazy dot'  => [ 1, q{f() if $l =~ m/\A.*?--/s;} ],
);

check_table(
    'without a capture, not a split at a separator',
    '/i'                            => [ 0, q{$l =~ s/\A[^x]*x//i;} ],
    '/g'                            => [ 0, q{$b =~ s/\A[^\n]*\n//g;} ],
    'caret under /m'                => [ 0, q{$b =~ s/^[^\n]*\n//m;} ],
    'a dot without /s'              => [ 0, q{$l =~ s/\A.*?://;} ],
    'greedy under /s'               => [ 0, q{$b =~ s/\A.*\n//s;} ],
    'unanchored'                    => [ 0, q{$b =~ s/[^\n]*\n//;} ],
    'a class of several'            => [ 0, q{$b =~ s/\A[^\n]*[\r\n]//;} ],
    'whitespace'                    => [ 0, q{$l =~ s/\A.*?\s//s;} ],
    'alternation'                   => [ 0, q{$l =~ s/\A.*?(?:,|;)//s;} ],
    'interpolation'                 => [ 0, q{$l =~ s/\A.*?$sep//s;} ],
    'a quantified separator'        => [ 0, q{$b =~ s/\A[^\n]*\n+//;} ],
    'a counted quantifier'          => [ 0, q{$b =~ s/\A[^\n]{2,}\n//;} ],
    'a narrower run'                => [ 0, q{$l =~ s/\A\w*://;} ],
    'something after the separator' => [ 0, q{$l =~ s/\A[^:]*:\s*//;} ],
    'no separator'                  => [ 0, q{$b =~ s/\A[^\n]*//;} ],
    'nothing before the separator'  => [ 0, q{$b =~ s/\A\n//;} ],
    'a replacement'                 => [ 0, q{$b =~ s/\A[^\n]*\n/x/;} ],
    'a compiled regex'              => [ 0, q{my $rx = qr/\A[^\n]*\n/;} ],
    'a group that captures nothing' => [ 0, q{$b =~ s/\A(?:[^\n]*)\n//;} ],
);

# Each form is told its own replacement.  The wording of the explanation is
# the policy's to choose, so only the part that names the replacement is checked.
my %explains = (
    q{my ($k) = $l =~ m/\A([^:]*):/;}   => q{take the text before it with substr},
    q{$b =~ s/\A([^\n]*)\n//;}          => q{take the text and the separator off with four-argument substr},
    q{$b =~ s/\A[^\n]*\n//;}            => q{up to and including it off with four-argument substr},
    q{f() if $l =~ m/\A[^:]*:/;}        => q{index() >= 0},
    q{my $r = $b =~ s/\A([^\n]*)\n//r;} => q{the text before it and the text after it with substr},
    q{my $r = $b =~ s/\A[^\n]*\n//r;}   => q{then take the text after it with substr},
);
foreach my $source ( sort keys %explains ) {
    my ($violation) = $critic->critique( \$source );
    my $explanation = $violation ? $violation->explanation : q{};
    ok( index( $explanation, $explains{$source} ) >= 0, "the explanation of $source" ) or diag $explanation;
}

is( scalar( () = warnings { Perl::Critic->new( -profile => q{}, '-single-policy' => $POLICY ) } ), 0, 'nothing warns on construction' );

done_testing();
