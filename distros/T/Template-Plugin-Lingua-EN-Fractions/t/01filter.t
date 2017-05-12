#!/usr/bin/perl -w
use strict;

use Template::Test;

test_expect(\*DATA);

__END__

# testing fraction2words filter with a block
--test--
[% USE Lingua.EN.Fractions; FILTER fraction2words -%]
3/4
[% END -%]
--expect--
three quarters


# text | fraction2words
--test--
[% USE Lingua.EN.Fractions -%]
[% '1 1/2' | fraction2words %]
[% text = '5/16'; text.fraction2words %]
[% text = '2 4/8'; text.fraction2words %]
--expect--
one and a half
five sixteenths
two and four eighths
