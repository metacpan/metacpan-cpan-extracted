#!/usr/bin/perl -w

use strict;
use Template::Test;

test_expect(\*DATA, undef, {});

__END__
--test--
[% USE Datum -%]
[% '2003-12-31' | datum %]
--expect--
31.12.2003

--test--
[% USE Datum -%]
[% 'lll' | datum %]
--expect--

--test--
[% USE Datum -%]
[% 0 | datum %]
--expect--

--test--
[% '20031231' | datum %]
--expect--
31.12.2003

--test--
[% '20031231143000' | datum %]
--expect--
31.12.2003 14:30:00

