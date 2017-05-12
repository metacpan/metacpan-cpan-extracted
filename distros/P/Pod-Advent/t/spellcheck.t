#!perl

use strict;
use warnings;
use Test::More;
use Pod::Advent;
use Test::Differences;

eval "use Text::Aspell";
plan skip_all => "Text::Aspell required for testing spellcheck" if $@;

# for the case of an empty package, which is useful for testing with.
eval { Text::Aspell->can('new') } or
  plan skip_all => "Text::Aspell required for testing spellcheck";

plan tests => 26;

my $advent = Pod::Advent->new;

ok( $Pod::Advent::speller, "got speller" )
  or exit;
isa_ok( $Pod::Advent::speller, 'Text::Aspell', "got Text::Aspell" );
is( $advent->spellcheck_enabled, 1, "spellcheck enabled" );
is( $Pod::Advent::speller->get_option('lang'), 'en_US', "en_US dictionary" );

my $s;
$advent->output_string( \$s );
$advent->parse_file( \*DATA );

is( $advent->num_spelling_errors, 20, "misspelled word ct" );
eq_or_diff( [ $advent->spelling_errors ], [qw/
	z1
	z2
	z3
	z4
	z5
	z6
	z3
	z9
	z15
	z16
	z20
	z21
	z22
	z23
	z24
	z25
	z26
	z27
	z28
	z29
/], "misspelled words" );

$advent->__reset();
is( $advent->num_spelling_errors, 0, "<reset> misspelled word ct" );
is_deeply( [ $advent->spelling_errors ], [qw/ /], "<reset> misspelled words" );

my $text;

$text = "";
is( $advent->__spellcheck($text), 0, "[$text] spellcheck return val" );
is( $advent->num_spelling_errors, 0, "[$text] misspelled word ct" );
is_deeply( [ $advent->spelling_errors ], [qw/ /], "[$text] misspelled words" );

$text = "word";
is( $advent->__spellcheck($text), 0, "[$text] spellcheck return val" );
is( $advent->num_spelling_errors, 0, "[$text] misspelled word ct" );
is_deeply( [ $advent->spelling_errors ], [qw/ /], "[$text] misspelled words" );

$text = "bad z1 and z2 a";
is( $advent->__spellcheck($text), 2, "[$text] spellcheck return val" );
is( $advent->num_spelling_errors, 2, "[$text] misspelled word ct" );
is_deeply( [ $advent->spelling_errors ], [qw/z1 z2/], "[$text] misspelled words" );

$text = "spell";
is( $advent->__spellcheck($text), 0, "[$text] spellcheck return val" );
is( $advent->num_spelling_errors, 2, "[$text] misspelled word ct" );
is_deeply( [ $advent->spelling_errors ], [qw/z1 z2/], "[$text] misspelled words" );

$text = "1234";
is( $advent->__spellcheck($text), 0, "[$text] spellcheck return val" );
is( $advent->num_spelling_errors, 2, "[$text] misspelled word ct" );
is_deeply( [ $advent->spelling_errors ], [qw/z1 z2/], "[$text] misspelled words" );

$text = "more z3 bad z4";
is( $advent->__spellcheck($text), 2, "[$text] spellcheck return val" );
is( $advent->num_spelling_errors, 4, "[$text] misspelled word ct" );
is_deeply( [ $advent->spelling_errors ], [qw/z1 z2 z3 z4/], "[$text] misspelled words" );

__DATA__
=pod

z1 word B<word z2> word I<z3> B<z4 I<z5> word z6>
repeated z3

A<http://example.z07.com>
A<http://example.z08.com|z9>

M<z010>
N<z011>

L<z012>
F<z013>

C<z014>
I<z15>
B<z16>

=begin code

z017

=end code

=begin codeNNN

z018

=end codeNNN

=begin pre

z019

=end pre

=begin eds

z20

=end eds

=head1 z21

z22

=head2 z23

z24

=head3 z25

z26

=head4 z27

z28

=begin footnote z011

Blah z29

=end footnote

Some D<block of z030 exempt from spellcheck>

=cut
