#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin);

use Test::More tests => 10;

SKIP:
{
  eval { require Image::Size };

  if($@)
  {
    skip("all tests: could not load Image::Size", 6);
  }

  use_ok('Rose::HTML::Image');

  my $image = Rose::HTML::Image->new(
    document_root => $Bin,
    src           => '/logo.png');

  ok(ref $image eq 'Rose::HTML::Image', 'new()');

  is($image->html, '<img alt="" height="48" src="/logo.png" width="72">', 'html() 1');
  is($image->xhtml, '<img alt="" height="48" src="/logo.png" width="72" />', 'xhtml_field() 1');

  $image->class('foo');
  $image->id('bar');
  $image->style('baz');
  $image->alt('logo');

  is($image->html, '<img alt="logo" class="foo" height="48" id="bar" src="/logo.png" style="baz" width="72">', 'html() 2');
  is($image->xhtml, '<img alt="logo" class="foo" height="48" id="bar" src="/logo.png" style="baz" width="72" />', 'xhtml() 2');

  $image = Rose::HTML::Image->new(
    src           => '/logo.png',
    document_root => $Bin);

  is($image->html, '<img alt="" height="48" src="/logo.png" width="72">', 'html() 3');
  is($image->xhtml, '<img alt="" height="48" src="/logo.png" width="72" />', 'xhtml_field() 3');

  $image = Rose::HTML::Image->new(src => '/logo.png');
  $image->document_root($Bin);

  is($image->html, '<img alt="" height="48" src="/logo.png" width="72">', 'html() 4');
  is($image->xhtml, '<img alt="" height="48" src="/logo.png" width="72" />', 'xhtml_field() 4');
}
