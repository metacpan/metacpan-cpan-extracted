#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which matches the policy reads as stripping a prefix or suffix, and which it leaves alone

=head1 DESCRIPTION

Tables of snippets that must be reported and a table that must not.

A reported match is an anchor, one capture and a run of literal text, in either
order, with the capture's far end anchored or reached by C<.*> or C<.+>.  The
edges are the anchors (which count, and what C</m> does to them), what counts as
literal text, the modifiers that change what the pattern means, and what is not
a match at all.

=cut

use Test::More;
use Test::Warnings qw{warnings};

use Perl::Critic;

# Loaded so that a syntax error in it is a compile failure here rather than
# Perl::Critic reporting no such policy.  Named as a string below, which is
# what ProhibitUnusedImports cannot see.
use Perl::Critic::Policy::RegularExpressions::ProhibitRegexToStripAffix;    ## no critic (ProhibitUnusedImports)

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for a
# .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  The anchored long name because -single-policy is a pattern.
my $POLICY = '^Perl::Critic::Policy::RegularExpressions::ProhibitRegexToStripAffix$';

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
    'a suffix',
    'anchored at both ends'      => [ 1, q{my ($n) = $f =~ m/\A(\w+)\.pm\z/;} ],
    'caret and dollar'           => [ 1, q{my ($n) = $f =~ m/^(.*)\.tar\.gz$/;} ],
    'capital Z'                  => [ 1, q{my ($n) = $f =~ m/\A(.*)\.pm\Z/;} ],
    'dot star reaches the start' => [ 1, q{my ($n) = $f =~ m/(.*)\.bak\z/;} ],
    'dot plus reaches the start' => [ 1, q{my ($n) = $f =~ m/(.+)\.bak\z/;} ],
    'under /x'                   => [ 1, q{my ($n) = $f =~ m/\A(\w+) \. pm\z/x;} ],
    'under /x with a comment'    => [ 1, qq{my (\$n) = \$f =~ m/\\A(\\w+) # the name\n \\.pm\\z/x;} ],
    'under /s'                   => [ 1, q{my ($n) = $f =~ m/\A(.*)\.pm\z/s;} ],
    'bare slashes'               => [ 1, q{my ($n) = $f =~ /\A(\w+)\.pm\z/;} ],
    'other delimiters'           => [ 1, q{my ($n) = $f =~ m{\A(\w+)\.pm\z};} ],
    'against the topic'          => [ 1, q{my @n = map { m/\A(\w+)\.pm\z/ ? $1 : () } @files;} ],
    '/m with string anchors'     => [ 1, q{my ($n) = $f =~ m/\A(\w+)\.pm\z/m;} ],
);

check_table(
    'a prefix',
    'anchored at both ends'        => [ 1, q{my ($r) = $l =~ m/\Aprefix-(.*)\z/;} ],
    'dot star reaches the end'     => [ 1, q{my ($r) = $l =~ m/\Afoo:(.*)/;} ],
    'caret'                        => [ 1, q{my ($r) = $l =~ m/^foo:(.+)/;} ],
    'a word capture, both anchors' => [ 1, q{my ($r) = $l =~ m/^v(\d+)$/;} ],
);

check_table(
    'not an affix',
    'unanchored'                 => [ 0, q{my ($n) = $f =~ m/(\w+)\.pm\z/;} ],
    'prefix with a far end open' => [ 0, q{my ($r) = $l =~ m/\Av(\d+)/;} ],
    'no anchor at all'           => [ 0, q{my ($n) = $f =~ m/(.*)\.pm/;} ],
    'alternation'                => [ 0, q{my ($n) = $f =~ m/\A(\w+)\.(?:pm|pl)\z/;} ],
    'two captures'               => [ 0, q{my ($n, $e) = $f =~ m/\A(\w+)\.(pm)\z/;} ],
    'a nested capture'           => [ 0, q{my ($n) = $f =~ m/\A((\w)\w*)\.pm\z/;} ],
    'a character class'          => [ 0, q{my ($n) = $f =~ m/\A(\w+)[.]pm\z/;} ],
    'interpolation'              => [ 0, q{my ($n) = $f =~ m/\A(\w+)$ext\z/;} ],
    'nothing to strip'           => [ 0, q{my ($n) = $f =~ m/\A(\w+)\z/;} ],
    'a quantified literal'       => [ 0, q{my ($n) = $f =~ m/\A(\w+)x+\z/;} ],
    'literal on both sides'      => [ 0, q{my ($n) = $f =~ m/\Aa(\w+)b\z/;} ],
    'no capture'                 => [ 0, q{f() if $f =~ m/\A\w+\.pm\z/;} ],
    '/i'                         => [ 0, q{my ($n) = $f =~ m/\A(\w+)\.pm\z/i;} ],
    '/g'                         => [ 0, q{my @n = $f =~ m/\A(\w+)\.pm\z/g;} ],
    '/m with line anchors'       => [ 0, q{my ($n) = $f =~ m/^(.*)\.pm$/m;} ],
    'a substitution'             => [ 0, q{$f =~ s/\.pm\z//;} ],
    'a compiled regex'           => [ 0, q{my $rx = qr/\A(\w+)\.pm\z/;} ],
);

is( scalar( () = warnings { Perl::Critic->new( -profile => q{}, '-single-policy' => $POLICY ) } ), 0, 'nothing warns on construction' );

done_testing();
