#!perl

use strict;
use warnings;

use Template::Test;


test_expect(\*DATA, undef, {});

__END__
--test--
[% USE Komma -%]
[% 123456 | komma0 %]
--expect--
123.456

--test--
[% USE Komma -%]
[% 123456.789 | komma0 %]
--expect--
123.457

--test--
[% USE Komma -%]
[% 1.4 | komma0 %]
--expect--
1

--test--
[% USE Komma -%]
[% 1.5 | komma0 %]
--expect--
2

--test--
[% USE Komma -%]
[% 1.6 | komma0 %]
--expect--
2

--test--
[% USE Komma -%]
[% -123456 | komma0 %]
--expect--
-123.456

--test--
[% USE Komma -%]
[% -123456.789 | komma0 %]
--expect--
-123.457

--test--
[% USE Komma -%]
[% 0 | komma0 %]
--expect--
0

--test--
[% USE Komma -%]
[% '' | komma0 %]
--expect--


--test--
[% USE Komma -%]
[% -1.4 | komma0 %]
--expect--
-1

--test--
[% USE Komma -%]
[% -1.5 | komma0 %]
--expect--
-2

--test--
[% USE Komma -%]
[% -1.6 | komma0 %]
--expect--
-2

