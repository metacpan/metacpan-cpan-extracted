#!/usr/bin/perl -w
use strict;

use Template::Test;

test_expect(\*DATA);

__END__

# testing nc filter with a block
--test--
[% USE Lingua.EN.NameCase; FILTER nc -%]
Macdonald
[% END -%]
--expect--
MacDonald


# text | nc
--test--
[% USE Lingua.EN.NameCase -%]
[% 'Macdonald' | nc %]
[% text = 'henry viii'; text.nc %]
[% text = 'Von Trapp'; text.nc %]
--expect--
MacDonald
Henry VIII
von Trapp
