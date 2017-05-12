use strict;
use Template::Test;

test_expect(\*DATA, undef, { price => 10000 });

__END__
--test--
[% USE CSV.Escape -%]
[% FILTER csv -%]
foo
[%- END %]
--expect--
"foo"

--test--
[% USE CSV.Escape -%]
[% FILTER csv -%]
b"a"r
[%- END %]
--expect--
"b""a""r"

--test--
[% USE CSV.Escape('csv_escape') -%]
[% FILTER csv_escape -%]
foo
bar
[%- END %]
--expect--
"foo
bar"

