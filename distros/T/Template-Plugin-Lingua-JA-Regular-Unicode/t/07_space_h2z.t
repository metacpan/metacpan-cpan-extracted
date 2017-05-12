use strict;
use utf8;
use Template::Test;

test_expect( \*DATA );

__END__
--test--
[% USE Lingua.JA.Regular.Unicode -%]
[% " eee" | space_h2z %]
--expect--
　eee
