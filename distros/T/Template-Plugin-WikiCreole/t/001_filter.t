#!/usr/bin/perl

use strict;
use Template::Test;

test_expect(\*DATA);

__END__
-- test --
Paragraphs
[% USE WikiCreole -%]
[% FILTER $WikiCreole -%]
Paragraph 1

Paragraph 2
[% END %]
-- expect --
Paragraphs
<p>Paragraph 1</p>

<p>Paragraph 2</p>
-- test --
Headings
[% USE WikiCreole -%]
[% FILTER $WikiCreole -%]
=Heading=
[% END %]
-- expect --
Headings
<h1>Heading</h1>
