#!/usr/bin/perl -w

use strict;

use Test::More tests => 14;

BEGIN
{
  use_ok('Rose::HTML::Anchor');
  use_ok('Rose::HTML::Image');
}

my $a = Rose::HTML::Anchor->new(href => 'apple.html', link => 'Apple');

is($a->link->[0]->html, 'Apple', 'link 1');
is($a->href, 'apple.html', 'href');

is($a->html,'<a href="apple.html">Apple</a>', 'html 1');
is($a->xhtml, '<a href="apple.html">Apple</a>', 'xhtml 2');

$a->link(Rose::HTML::Image->new(src => 'a.gif'));

is($a->html, '<a href="apple.html"><img alt="" src="a.gif"></a>', 'html 2');
is($a->xhtml, '<a href="apple.html"><img alt="" src="a.gif" /></a>', 'xhtml 2');

my $img = Rose::HTML::Image->new(src => 'b.gif');

$a->link($img, 'foo');

is($a->html, '<a href="apple.html"><img alt="" src="b.gif">foo</a>', 'html 3');
is($a->xhtml, '<a href="apple.html"><img alt="" src="b.gif" />foo</a>', 'xhtml 3');

is($a->start_html, '<a href="apple.html">', 'start_html 1');
is($a->end_html, '</a>', 'end_html 1');

is($a->start_xhtml, '<a href="apple.html">', 'start_xhtml 1');
is($a->end_xhtml, '</a>', 'end_xhtml 1');
