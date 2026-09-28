#!/usr/bin/env perl
#
# value_counts(): a key is the value's stringification, including its
# character/byte identity.
#
# Up to 0.315 increment_count() hashed the SV's bytes with a positive length,
# which is hv_fetch()'s way of saying "these are bytes".  The UTF-8 flag was
# thrown away with it, so the one-character string "\x{263A}" and the
# three-byte string "\xe2\x98\xba" -- byte-identical once encoded, and distinct
# to `eq`, to a Perl hash and to uniq() -- were counted as one value, and the
# key came back flagged wrong.
#
# There is no R or SciPy reference for this: it is a question about Perl string
# identity, and the definition is what a Perl hash does with the same values.
# So every case below is checked against a hand-built `$h{$_}++` hash, which is
# the specification, and against uniq(), which has carried the flag in its key
# (uniq_take()) since 0.302 and so was already right.
#
# The two directions that matter, and they pull opposite ways:
#
#   "\x{e9}" and "\xe9"            are the SAME value  (`eq` is true: both are
#                                  one character, U+00E9), and a Perl hash
#                                  canonicalises the UTF-8 one down to bytes.
#   "\x{263A}" and "\xe2\x98\xba"  are DIFFERENT values (`eq` is false: one
#                                  character against three), even though the
#                                  first encodes to the second's bytes.
#
# Getting only the first right is what a positive length does; getting only the
# second right is what a negative length alone would do.  The sign has to
# follow the SV.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(value_counts uniq);

# Built with explicit escapes rather than literal source characters so that
# this file needs no `use utf8` and its meaning does not depend on the encoding
# it is saved in.
my $smiley_chr   = "\x{263A}";              # one character, U+263A
my $smiley_bytes = "\xe2\x98\xba";          # three bytes: its UTF-8 encoding
my $eacute_chr   = "\x{e9}";                # one character, U+00E9
my $eacute_byte  = "\xe9";                  # one byte, the same character
my $ascii        = "plain";

cmp_ok($smiley_chr, 'ne', $smiley_bytes, 'the premise: smiley char ne its bytes');
cmp_ok($eacute_chr, 'eq', $eacute_byte,  'the premise: U+00E9 eq its byte');

my @data = ($smiley_chr, $smiley_bytes, $smiley_chr, $smiley_bytes,
            $eacute_chr, $eacute_byte,  $eacute_chr,
            $ascii, $ascii, $ascii,
            1, 1, '1', 2.5, '2.5');

# the specification: what a plain Perl hash makes of the same list
my %want;
$want{$_}++ for @data;

my $got = value_counts(\@data);

is(scalar keys %$got, scalar keys %want,
   'value_counts finds the same number of distinct values as a Perl hash');
is_deeply($got, \%want, 'value_counts agrees with a Perl hash, key for key');

# uniq() reached the same question by a different route and has been right
# since 0.302; the two must not disagree about what "distinct" means.
my @u = uniq(@data);
is(scalar @u, scalar keys %want, 'uniq agrees on the number of distinct values');

# the two cases the byte-only key conflated / would have conflated
is($got->{$smiley_chr},   2, 'the character U+263A is counted on its own');
is($got->{$smiley_bytes}, 2, 'its three-byte encoding is counted separately');
is($got->{$eacute_chr},   3, 'U+00E9 and its single byte are one value');

# the key that comes back must be the string it stands for, flag and all
my ($smiley_key) = grep { length($_) == 1 && ord($_) == 0x263A } keys %$got;
ok(defined $smiley_key, 'the U+263A key comes back as one character')
	or diag('keys: ', join ' ', map { join('.', map { sprintf '%02x', ord } split //) } keys %$got);
ok(utf8::is_utf8($smiley_key), 'the U+263A key keeps its UTF-8 flag');

# A key that is pure ASCII must not acquire one, so that a round trip through
# value_counts does not change a plain string.
my ($ascii_key) = grep { $_ eq $ascii } keys %$got;
ok(defined $ascii_key && !utf8::is_utf8($ascii_key),
   'an ASCII key is not flagged UTF-8');

# Numbers still key by their stringification, which is the documented rule and
# is the path nk_num_pv() renders (always ASCII, so always a positive length).
is($got->{1},   3, 'the integers 1, 1 and the string "1" are one value');
is($got->{2.5}, 2, 'the number 2.5 and the string "2.5" are one value');

# ... and the same for a frame column, which is the other way in
{
	my $vc = value_counts({ col => [ $smiley_chr, $smiley_bytes, $smiley_chr ] }, 'col');
	is($vc->{$smiley_chr},   2, 'HoA column: the character is counted on its own');
	is($vc->{$smiley_bytes}, 1, 'HoA column: its encoding is counted separately');
}

done_testing();
