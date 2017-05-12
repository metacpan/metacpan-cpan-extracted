use strict;
use warnings;
use utf8;
use Template::Test;

test_expect(\*DATA);

__DATA__
[% USE Ligature %]

--test--
[% 'offloading floral offices refines effectiveness' | ligature %]
--expect--
oﬄoading ﬂoral oﬃces reﬁnes eﬀectiveness
