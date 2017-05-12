#!/usr/bin/env perl
# test that the sub code we're generating in t/01_misc.t actually works.
use warnings;
use strict;
use Test::More;
use charnames ':full';
sub InDomainLabel {
    <<'END' }
30 39
61 7A
E0 F6
F8 FF
153
161
17E
END
my @valid =
  ('abcdefghi01234', '0123', "gr\N{LATIN SMALL LETTER U WITH DIAERESIS}nauer",);
my @not_valid =
  ('0-1', '-', 'Capitals', "foobar\N{INVERTED EXCLAMATION MARK}",);

sub is_valid {
    my $value = shift;
    /^\p{InDomainLabel}+$/;
}
plan tests => @valid + @not_valid;
ok(is_valid($_),  "$_ is a valid string")     for @valid;
ok(!is_valid($_), "$_ is not a valid string") for @not_valid;
