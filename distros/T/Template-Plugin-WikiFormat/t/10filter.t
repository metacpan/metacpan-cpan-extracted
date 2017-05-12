#!/usr/bin/perl -w
use strict;

use Text::WikiFormat;
use Template::Test;     # part of Template::Toolkit

test_expect(\*DATA);

__END__
-- test --
Paragraphs
[% USE WikiFormat -%]
[% FILTER $WikiFormat -%]
Paragraph 1

Paragraph 2
[% END %]
-- expect --
Paragraphs
<p>Paragraph 1</p>
<p>Paragraph 2</p>
-- test --
Headings
[% USE WikiFormat -%]
[% FILTER $WikiFormat -%]
= Heading =
[% END %]
-- expect --
Headings
<h1>Heading</h1>
-- test --
Wiki links
[% USE WikiFormat prefix = "http://www.mysite.com/?page=" -%]
[% FILTER $WikiFormat -%]
WikiLink
[% END %]
-- expect --
Wiki links
<p><a href="http://www.mysite.com/?page=WikiLink">WikiLink</a></p>
-- test --
Wiki link with slash
[% USE WikiFormat prefix = "http://www.mysite.com/?page=", extended = 1 -%]
[% FILTER $WikiFormat -%]
[foo/bar]
[% END %]
-- expect --
Wiki link with slash
<p><a href="http://www.mysite.com/?page=foo%2Fbar">foo/bar</a></p>
-- test --
Wiki link with slash
[% USE WikiFormat prefix = "http://www.mysite.com/?page=", 
extended = 1,
global_replace = [['%2F','/']] -%]
[% FILTER $WikiFormat -%]
[foo/bar]
[% END %]
-- expect --
Wiki link with slash
<p><a href="http://www.mysite.com/?page=foo/bar">foo/bar</a></p>
