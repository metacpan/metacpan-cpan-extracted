#!/usr/bin/perl -w

use strict;

use Test::More tests => 13;

BEGIN
{
  use_ok('Rose::HTML::Text');
}

my $o = Rose::HTML::Text->new('I <3 HTML');

is($o->html, 'I &lt;3 HTML', 'html 1');
is($o, 'I &lt;3 HTML', 'html (overloaded)');
is($o->xhtml, 'I &lt;3 HTML', 'xhtml 1');

$o->html('<b>foo</b>');

is($o->text, '<b>foo</b>', 'text 1');
is($o->html, '<b>foo</b>', 'html 2');
is($o->xhtml, '<b>foo</b>', 'xhtml 2');

eval { $o->html_attr(class => 'abc') };

ok($@, 'html_attr 1');

foreach my $method (qw(push_children push_child add_children add_child unshift_children))
{
  eval { $o->$method('foo') };
  ok($@, $method);
}
