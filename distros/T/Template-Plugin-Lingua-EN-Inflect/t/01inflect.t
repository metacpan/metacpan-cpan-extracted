#!/usr/bin/perl -w
use strict;

use Template::Test;

test_expect(\*DATA);

__END__
--test--
[%- # testing inflect filter with a block
    USE Lingua.EN.Inflect;
    FILTER inflect(number => 42); -%]
There PL_V(was) NO(error).
PL_ADJ(This) PL_N(error) PL_V(was) fatal.
[%
    END;
 -%]
--expect--
There were 42 errors.
These errors were fatal.

--test--
[% USE Lingua.EN.Inflect -%]
[% "NUM(3) PL_N(error)." | inflect -%]
--expect--
3 errors.

--test--
[% USE i = Lingua.EN.Inflect -%]
[% "NUM(0,0)There PL_V(was) NO(error)." | inflect -%]
--expect--
There were no errors.

--test--
[%- # testing inflect
    USE inflect = Lingua.EN.Inflect;
    "NUM(0,0)There PL_V(was) NO(error)." | inflect;
-%]
--expect--
There were no errors.

--test--
[%  # testing inflect
    USE Lingua.EN.Inflect;
    "NUM(1,0)There PL_V(was) NO(error)." | inflect;
 -%]
--expect--
There was 1 error.

--test--
[%- # testing inflect
    USE Lingua.EN.Inflect;
    "NUM(3,0)There PL_V(was) NO(error)." | inflect;
 -%]
--expect--
There were 3 errors.

--test--
[%- # testing inflect
    USE Lingua.EN.Inflect;
    "There PL_V(was) NO(error)." | inflect(number => 5);
 -%]
--expect--
There were 5 errors.

--test--
[%  # testing NO()
    USE i = Lingua.EN.Inflect;
    FOREACH n IN [ 0, 1, 2, 3, 42 ];
        i.NO('cat', n);
        ', ' UNLESS loop.last;
    END;
 -%]
--expect--
no cats, 1 cat, 2 cats, 3 cats, 42 cats

--test--
[%  # testing NUMWORDS() for 1, 2, 3, ...
    USE i = Lingua.EN.Inflect;
    FOREACH n IN [ 1, 2, 3, 4, 42, 1000 ];
        i.NUMWORDS(n);
        ', ' UNLESS loop.last;
    END;
 -%]
--expect--
one, two, three, four, forty-two, one thousand

--test--
[%  # testing ORD()
    USE Lingua.EN.Inflect;
    FOREACH n IN [ 1, 2, 3, 4, 5, 100 ];
        Lingua.EN.Inflect.ORD(n);
        ', ' UNLESS loop.last;
    END;
 -%]
--expect--
1st, 2nd, 3rd, 4th, 5th, 100th
