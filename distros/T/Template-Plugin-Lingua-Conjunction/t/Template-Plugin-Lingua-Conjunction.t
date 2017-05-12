use strict;
use blib;
use Template::Test;

test_expect(\*DATA);

# XXX should test various settings methods
__DATA__
--test--
[% USE conj=Lingua.Conjunction -%]
[% conj.conjunction("one") -%]
--expect--
one

--test--
[% USE c=Lingua.Conjunction -%]
[% c.list("one", "two") -%]
--expect--
one and two

--test--
[% USE Lingua.Conjunction -%]
[% Lingua.Conjunction.list("one", [ "two", "three" ]) -%]
--expect--
one, two, and three
