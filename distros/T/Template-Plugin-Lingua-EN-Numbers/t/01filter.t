#!/usr/bin/perl -w
use strict;

use Template::Test;

test_expect(\*DATA);

__END__

# testing num2en filter with a block
--test--
[% USE Lingua.EN.Numbers; FILTER num2en -%]
123
[% END -%]
--expect--
one hundred and twenty-three


# text | num2en
--test--
[% USE Lingua.EN.Numbers -%]
[% '123' | num2en %]
[% text = '124'; text.num2en %]
--expect--
one hundred and twenty-three
one hundred and twenty-four


# FILTER num2en_ordinal; ...
--test--
[% USE Lingua.EN.Numbers; FILTER num2en_ordinal -%]
54
[% END -%]
--expect--
fifty-fourth


# text | num2en_ordinal
--test--
[% USE Lingua.EN.Numbers -%]
[% '54' | num2en_ordinal %]
[% text = '53'; text.num2en_ordinal %]
--expect--
fifty-fourth
fifty-third


# testing year2en filter with a block
--test--
[% USE Lingua.EN.Numbers; FILTER year2en -%]
1984
[% END -%]
--expect--
nineteen eighty-four


# text | year2en
--test--
[% USE Lingua.EN.Numbers -%]
[% '2014' | year2en %]
[% text = '1965'; text.year2en %]
--expect--
twenty fourteen
nineteen sixty-five


# testing ordinate filter with a block
--test--
[% USE Lingua.EN.Numbers; FILTER ordinate -%]
3[% END -%]
--expect--
3rd


# text | ordinate
--test--
[% USE Lingua.EN.Numbers -%]
[% '11' | ordinate %]
[% text = '101'; text.ordinate %]
--expect--
11th
101st

