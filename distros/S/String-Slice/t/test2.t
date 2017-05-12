use strict;
use warnings;

use open ':std', ':encoding(utf8)';
use Test::More;
use utf8;

use String::Slice;

# String char-len=20 byte-line=23 + \0
my $string = "Ingy döt Nët döt Com";
my $slice = "";

my $return = slice($slice, $string);
is $return, 1, 'Return value is 1';
is length($slice), 20, 'Length matches original';
is $slice, $string, "First slice matches '$string'";

for my $i (0, 5, 9, 13, 9, 17, 20, 9, 0) {
    $return = slice($slice, $string, $i);
    is $return, 1, "Offset $i works";
    is length($slice), 20 - $i, 'Length is rest of string';
    my $substr = substr($string, $i);
    is $slice, $substr, "Slice content is '$substr'";
}

done_testing;
