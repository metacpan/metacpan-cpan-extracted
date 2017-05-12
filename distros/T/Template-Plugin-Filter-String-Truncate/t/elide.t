#!/usr/bin/env perl

use strict;
use Template::Test;

test_expect(\*DATA);

__END__
--test--
[% USE Filter.String.Truncate -%]
[% FILTER elide(16) -%]
This is your brain
[%- END %]
--expect--
This is your ...
--test--
[% USE Filter.String.Truncate -%]
[% FILTER elide(16, truncate => 'left') -%]
This is your brain
[%- END %]
--expect--
...is your brain
--test--
[% USE Filter.String.Truncate -%]
[% FILTER elide(16, truncate => 'middle') -%]
This is your brain
[%- END %]
--expect--
This is... brain
