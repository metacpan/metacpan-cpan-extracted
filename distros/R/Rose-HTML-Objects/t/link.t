#!/usr/bin/perl -w

use strict;

use Test::More tests => 5;

BEGIN
{
  use_ok('Rose::HTML::Link');
}

my $l = Rose::HTML::Link->new(rel => 'stylesheet', href => '/style/main.css');

is($l->rel, 'stylesheet', 'rel');
is($l->href, '/style/main.css', 'href');

is($l->html,'<link href="/style/main.css" rel="stylesheet">', 'html');
is($l->xhtml, '<link href="/style/main.css" rel="stylesheet" />', 'xhtml');
