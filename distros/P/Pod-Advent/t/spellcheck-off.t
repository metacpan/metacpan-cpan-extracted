#!perl

use strict;
use warnings;
use Test::More tests => 4;
use Pod::Advent;

package Text::Aspell;
sub new {
  die;  # force failure on loading of Text::Aspell;
}

package main;

my $advent = Pod::Advent->new;

is( $Pod::Advent::speller, undef, "no speller" );
is( $advent->spellcheck_enabled, 0, "spellcheck disabled" );

my $s;
$advent->output_string( \$s );
$advent->parse_file( \*DATA );

is( $advent->num_spelling_errors, 0, "no misspelled word ct" );
is_deeply( [ $advent->spelling_errors ], [],  "no misspelled words" );

__DATA__
=pod

z1 word B<word z2> word I<z3> B<z4 I<z5> word z6>
repeated z3

=cut
