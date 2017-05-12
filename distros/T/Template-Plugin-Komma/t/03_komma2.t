#!perl

use strict;
use warnings;

use Template::Test;


test_expect(\*DATA, undef, {});

__END__
--test--
[% USE Komma -%]
[% 123456 | komma2 %]
--expect--
123.456,00

--test--
[% USE Komma -%]
[% 123456.789 | komma2 %]
--expect--
123.456,79

--test--
[% USE Komma -%]
[% 1.234 | komma2 %]
--expect--
1,23

--test--
[% USE Komma -%]
[% 1.235 | komma2 %]
--expect--
1,24

--test--
[% USE Komma -%]
[% 1.236 | komma2 %]
--expect--
1,24

--test--
[% USE Komma -%]
[% -123456 | komma2 %]
--expect--
-123.456,00

--test--
[% USE Komma -%]
[% -123456.789 | komma2 %]
--expect--
-123.456,79

--test--
[% USE Komma -%]
[% 0 | komma2 %]
--expect--
0,00

--test--
[% USE Komma -%]
[% '' | komma2 %]
--expect--


--test--
[% USE Komma -%]
[% -1.234 | komma2 %]
--expect--
-1,23

--test--
[% USE Komma -%]
[% -1.235 | komma2 %]
--expect--
-1,24

--test--
[% USE Komma -%]
[% -1.236 | komma2 %]
--expect--
-1,24

