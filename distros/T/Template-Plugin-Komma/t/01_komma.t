use strict;
use Template::Test;

test_expect(\*DATA, undef, {});

__END__
--test--
[% USE Komma -%]
[% 123456 | komma %]
--expect--
123.456

--test--
[% USE Komma -%]
[% 123456.789 | komma %]
--expect--
123.456,789

--test--
[% USE Komma -%]
[% -123456 | komma %]
--expect--
-123.456

--test--
[% USE Komma -%]
[% -123456.789 | komma %]
--expect--
-123.456,789

--test--
[% USE Komma -%]
[% 0 | komma %]
--expect--
0

--test--
[% USE Komma -%]
[% '' | komma %]
--expect--


