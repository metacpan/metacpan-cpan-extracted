#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which clearings of a variable the policy reports, and which it leaves alone

=head1 DESCRIPTION

A table of snippets that must be reported and a table that must not.

The cases that matter are the ways a variable can still be read after it is
emptied: a later statement, a string that interpolates it, a reference, a
closure, the next pass of a loop, or the next call of a sub.

=cut

use Test::More;
use Test::Warnings qw{warnings};

use Perl::Critic;

# Loaded so that a syntax error in it is a compile failure here rather than
# Perl::Critic reporting no such policy.  Named as a string below, which is
# what ProhibitUnusedImports cannot see.
use Perl::Critic::Policy::Variables::ProhibitUselessVarClearing;    ## no critic (ProhibitUnusedImports)

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for a
# .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  The anchored long name because -single-policy is a pattern.
my $POLICY = '^Perl::Critic::Policy::Variables::ProhibitUselessVarClearing$';

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
    'emptied, and never read again',
    'a hash, before its block ends'               => [ 1, q{if ($w) { my %s = f(); g(%s); %s = (); }} ],
    'with statements after it'                    => [ 1, q{if ($w) { my %s = f(); g(%s); %s = (); h(1); }} ],
    'an array'                                    => [ 1, q{sub f { my @a = g(); h(@a); @a = (); return 1; }} ],
    'a hash reference replaced by an empty one'   => [ 1, q{sub f { my $hr = g(); h($hr); $hr = {}; }} ],
    'an array reference replaced by an empty one' => [ 1, q{sub f { my $ar = g(); h($ar); $ar = []; }} ],
    'a scalar set to undef'                       => [ 1, q{sub f { my $x = g(); h($x); $x = undef; }} ],
    'undef on a scalar'                           => [ 1, q{sub f { my $x = g(); h($x); undef $x; }} ],
    'undef with parens'                           => [ 1, q{sub f { my $x = g(); h($x); undef($x); }} ],
    'undef on a hash'                             => [ 1, q{sub f { my %h = g(); h(%h); undef %h; }} ],
    'undef on an array'                           => [ 1, q{sub f { my @a = g(); h(@a); undef @a; }} ],
    'at the level of the file'                    => [ 1, q{my %h = f(); g(%h); %h = ();} ],
    'in a branch of the block that declares'      => [ 1, q{my %h = f(); g(%h); if ($x) { %h = () }} ],
    'after a loop that reads it'                  => [ 1, q{my %h = f(); for (@x) { g(%h) } %h = ();} ],
    'in a bare block of the declaring block'      => [ 1, q{my %h = f(); g(%h); { %h = (); }} ],
    'a different name is mentioned later'         => [ 1, q{my %h = f(); g(%h); %h = (); g(%hh, "$hh{a}");} ],
);

check_table(
    'still read, or not a clearing',
    'read by a later statement'           => [ 0, q{my %h = f(); %h = (); g(%h);} ],
    'an element read later'               => [ 0, q{my %h = f(); %h = (); g($h{a});} ],
    'a slice read later'                  => [ 0, q{my %h = f(); %h = (); g(@h{qw{a b}});} ],
    'the last index read later'           => [ 0, q{my @a = f(); @a = (); g($#a);} ],
    'interpolated in a string later'      => [ 0, q{my %h = f(); %h = (); print "$h{a}";} ],
    'interpolated in a heredoc later'     => [ 0, qq{my \@a = f(); \@a = (); print <<"EOT";\n\@a\nEOT\n} ],
    'in a regular expression later'       => [ 0, q{my $x = f(); $x = undef; g() if m/$x/;} ],
    'a reference was taken'               => [ 0, q{my %h; my $r = \%h; %h = ();} ],
    'a closure mentions it'               => [ 0, q{my @a; my $f = sub { @a }; @a = ();} ],
    'a named sub mentions it'             => [ 0, q{my @a; sub f { return @a } @a = ();} ],
    'cleared inside a foreach'            => [ 0, q{my %h; for my $x (@y) { g(%h); %h = (); }} ],
    'cleared inside a while'              => [ 0, q{my @a; while (f()) { g(@a); @a = (); }} ],
    'cleared inside a named sub'          => [ 0, q{my %h; sub f { g(%h); %h = () }} ],
    'cleared inside a map block'          => [ 0, q{my @a; my @b = map { @a = (); $_ } @c;} ],
    'a package variable'                  => [ 0, q{our %h; %h = ();} ],
    'a variable nothing here declares'    => [ 0, q{%h = ();} ],
    'a state variable'                    => [ 0, q{use feature 'state'; sub f { state %h; %h = (); }} ],
    'the loop variable, an alias'         => [ 0, q{for my $x (@a) { $x = undef }} ],
    'given new values, not emptied'       => [ 0, q{my %h = f(); g(%h); %h = ( a => 1 );} ],
    'a new reference, not an empty one'   => [ 0, q{my $hr = f(); g($hr); $hr = { a => 1 };} ],
    'the hash a reference points to'      => [ 0, q{my $hr = f(); g($hr); %$hr = ();} ],
    'the array a reference points to'     => [ 0, q{my $ar = f(); g($ar); @{$ar} = ();} ],
    'undef on what a reference points to' => [ 0, q{my $hr = f(); g($hr); undef %$hr;} ],
    'one element set to undef'            => [ 0, q{my %h = f(); g(%h); $h{a} = undef;} ],
    'a declaration that empties'          => [ 0, q{my %h = ();} ],
);

is_deeply( [ warnings { $critic->critique( \q{my %h; %h = ();} ) } ], [], 'and no warnings on the way' );

done_testing();
