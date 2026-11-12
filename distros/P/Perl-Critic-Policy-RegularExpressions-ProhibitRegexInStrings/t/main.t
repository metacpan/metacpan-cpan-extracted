#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which strings the policy reads as a regular expression, and which it leaves alone

=head1 DESCRIPTION

Tables of snippets that must be reported and a table that must not.

A reported string is the value of a key that names a regular expression, or
the one value of a scalar that a match in its scope uses.  The edges are the
spellings of a key, the kinds of string, a qr// in a string, the ways that a
match uses a scalar, and where in the file that use is.

=cut

use Test::More;
use Test::Warnings qw{warnings};

use Perl::Critic;

# Loaded so that a syntax error in it is a compile failure here rather than
# Perl::Critic reporting no such policy.  Named as a string below, which is
# what ProhibitUnusedImports cannot see.
use Perl::Critic::Policy::RegularExpressions::ProhibitRegexInStrings;    ## no critic (ProhibitUnusedImports)

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for a
# .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  The anchored long name because -single-policy is a pattern.
my $POLICY = '^Perl::Critic::Policy::RegularExpressions::ProhibitRegexInStrings$';

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
    'the value of a key',
    'pattern'                 => [ 1, q{my $s = { type => 'string', pattern => '^[a-z]+$' };} ],
    'regex'                   => [ 1, q{f( regex => '\A\d+\z' );} ],
    'regexp'                  => [ 1, q{f( regexp => '\A\d+\z' );} ],
    'a quoted key'            => [ 1, q{my $s = { 'pattern' => '^x$' };} ],
    'a double-quoted key'     => [ 1, q{my $s = { "pattern" => '^x$' };} ],
    'q{}'                     => [ 1, q{my $s = { pattern => q{^x$} };} ],
    'qq{}'                    => [ 1, q{my $s = { pattern => qq{^x$} };} ],
    'double quotes'           => [ 1, q{my $s = { pattern => "^x\$" };} ],
    'a string around a value' => [ 1, q{my $s = { pattern => "^$prefix-" };} ],
    'a string, then more'     => [ 1, q{my $s = { pattern => '^' . $x };} ],
    'two in one hash'         => [ 2, q{my $s = { a => { pattern => '^x$' }, b => { regex => '^y$' } };} ],
);

check_table(
    'a scalar that a match uses',
    'interpolated in m//'    => [ 1, q{my $name = '[A-Za-z]+'; f() if $v =~ m/\A$name\z/;} ],
    'interpolated in braces' => [ 1, q{my $name = '[A-Za-z]+'; f() if $v =~ m/\A${name}\z/;} ],
    'in a substitution'      => [ 1, q{my $ws = '\s+'; $v =~ s/$ws/ /g;} ],
    'in a qr//'              => [ 1, q{my $d = '\d+'; my $re = qr/\A$d\z/;} ],
    'bound with =~'          => [ 1, q{my $re = '\A\d+\z'; f() if $v =~ $re;} ],
    'bound with !~'          => [ 1, q{my $re = '\A\d+\z'; f() if $v !~ $re;} ],
    'given to split'         => [ 1, q{my $sep = '\s*,\s*'; my @p = split $sep, $line;} ],
    'given to split, in ()'  => [ 1, q{my $sep = '\s*,\s*'; my @p = split( $sep, $line );} ],
    'our'                    => [ 1, q{our $SEP = ','; my @p = split $SEP, $line;} ],
    'state'                  => [ 1, q{use feature 'state'; state $sep = ','; my @p = split $sep, $line;} ],
    'in a nested block'      => [ 1, q{my $re = '^x'; if ($y) { f() if $v =~ $re }} ],
    'double quotes'          => [ 1, q{my $re = "^x"; f() if $v =~ $re;} ],
);

check_table(
    'not a regular expression in a string',
    'a qr// in a string'                          => [ 0, q{my $s = { pattern => "$USER" };} ],
    'in braces'                                   => [ 0, q{my $s = { pattern => "${USER}" };} ],
    'of a package'                                => [ 0, q{my $s = { pattern => "$Trog::Utils::LINK_NAME" };} ],
    'qq{} of one scalar'                          => [ 0, q{my $s = { pattern => qq{$USER} };} ],
    'a qr//'                                      => [ 0, q{my $s = { pattern => qr/\A[a-z]+\z/ };} ],
    'a variable'                                  => [ 0, q{my $s = { pattern => $USER };} ],
    'another key'                                 => [ 0, q{my $s = { name => '^not a pattern$' };} ],
    'a key as a value'                            => [ 0, q{my @k = ( 'x' => 'pattern' );} ],
    'a key with a comma'                          => [ 0, q{my @k = ( pattern, '^x$' );} ],
    'a scalar no match uses'                      => [ 0, q{my $text = 'abc'; print $text;} ],
    'a scalar set to a qr//'                      => [ 0, q{my $sep = qr/\s*,\s*/; my @p = split $sep, $line;} ],
    'a string, then more'                         => [ 0, q{my $re = '^' . $x; f() if $v =~ $re;} ],
    'two scalars at once'                         => [ 0, q{my ( $a1, $b1 ) = ( '^x', '^y' ); f() if $v =~ $a1;} ],
    'an array'                                    => [ 0, q{my @re = ('^x'); f() if $v =~ $re[0];} ],
    'a match before it'                           => [ 0, q{f() if $v =~ $re; my $re = '^x';} ],
    'in another block'                            => [ 0, q{{ my $re = '^x'; } f() if $v =~ $re;} ],
    'split of something else'                     => [ 0, q{my $s = 'a,b'; my @p = split /,/, $s;} ],
    'the string that split splits'                => [ 0, q{my $s = 'a,b'; my @p = split( /,/, $s );} ],
    'one string for two scalars'                  => [ 0, q{my ( $re, $other ) = '^x'; f() if $v =~ $re;} ],
    'the subject of a match'                      => [ 0, q{my $s = 'abc'; f() if $s =~ m/b/;} ],
    'a scalar the match names in its replacement' => [ 0, q{my $to = 'x'; $v =~ s/a/$to/;} ],
);

my $narrow = Perl::Critic->new( -profile => \"[RegularExpressions::ProhibitRegexInStrings]\nkeys = match_re\n", '-single-policy' => $POLICY, -severity => 1 );
is( scalar $narrow->critique( \q{my $s = { match_re => '^x$' };} ), 1, 'keys: a key that the configuration names' );
is( scalar $narrow->critique( \q{my $s = { pattern => '^x$' };} ),  0, 'keys: replaces the default list' );

is( scalar( () = warnings { Perl::Critic->new( -profile => q{}, '-single-policy' => $POLICY ) } ), 0, 'nothing warns on construction' );

done_testing();
