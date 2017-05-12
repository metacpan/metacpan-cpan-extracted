#!/usr/bin/perl -w

use strict;
use Template::Test;

test_expect(\*DATA, undef, {});

__END__
--test--
[% USE Nbsp -%]
[% 123 | nbsp %]
--expect--
123

--test--
[% USE Nbsp -%]
[% '' | nbsp %]
--expect--
&nbsp;

--test--
[% USE Nbsp -%]
[% 0 | nbsp %]
--expect--
0

--test--
[% USE Nbsp -%]
[% undef_var | nbsp %]
--expect--
&nbsp;
