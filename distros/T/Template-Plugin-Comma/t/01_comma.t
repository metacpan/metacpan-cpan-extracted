use strict;
use Template::Test;

test_expect(\*DATA, undef, { price => 10000 });

__END__
--test--
[% USE Comma -%]
[% FILTER comma -%]
1000.00
[%- END %]
--expect--
1,000.00

--test--
[% USE Comma -%]
[% price | comma %]
--expect--
10,000

--test--
[% USE Comma -%]
[% FILTER comma -%]
This item costs 1000 yen.
[%- END %]
--expect--
This item costs 1,000 yen.

--test--
[% USE Comma -%]
This item costs [% 123 | comma %] yen.
--expect--
This item costs 123 yen.

--test--
[% USE Comma -%]
This item costs $[% 123.45 | comma %] USD.
--expect--
This item costs $123.45 USD.

--test--
[% USE Comma -%]
This item costs $[% 123.4567 | comma %] USD.
--expect--
This item costs $123.4567 USD.

--test--
[% USE Comma -%]
This item costs $[% 1234.56 | comma %] USD.
--expect--
This item costs $1,234.56 USD.

--test--
[% USE Comma -%]
This item costs $[% 1234.5678 | comma %] USD.
--expect--
This item costs $1,234.5678 USD.

--test--
[% USE Comma %][% 123.45 | comma %]
--expect--
123.45

--test--
[% USE Comma %][% 1234.5678 | comma %]
--expect--
1,234.5678

--test--
[% USE Comma %][% 1234567.8901 | comma %]
--expect--
1,234,567.8901

--test--
[% USE Comma -%]
[% FILTER comma -%]
.31
.3141592
0.3141592
3.141592
314.1592
31415.92653
3141592653.58
314159265358
[%- END %]
--expect--
.31
.3141592
0.3141592
3.141592
314.1592
31,415.92653
3,141,592,653.58
314,159,265,358
