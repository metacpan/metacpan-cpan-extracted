#! /usr/bin/perl
#---------------------------------------------------------------------
# Copyright 2010 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 24 Mar 2010
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test the parse_value method of PostScript::Report::LinkField
#---------------------------------------------------------------------

use Test::More;

use PostScript::Report::LinkField ();

my @tests = (
  'simple words' => ['simple words'],
  '[just a link](href)' => [ { text => 'just a link', url => 'href' }],
  'prefix [link](to) postfix' =>
    [ 'prefix ', { text => 'link', url => 'to' }, ' postfix' ],
  'quote brackets \[\]' => ['quote brackets []'],
  'close ] bracket' => ['close ] bracket'],
  'a < b' => ['a < b'],
  '<http://example.com>' => [ { text => 'http://example.com',
                                url => 'http://example.com' }],
  '<foo@example.com>' => [ { text => 'foo@example.com',
                             url => 'mailto:foo@example.com' }],
  'not \[a](link)' => ['not [a](link)'],
  'is \\\\[a](link)' => [ 'is \\', { text => 'a', url => 'link' } ],
  '<noClose'         => [ '<noClose' ],
  '<<http://example.com>>' => [ '<', { text => 'http://example.com',
                                       url => 'http://example.com' }, '>'],
  '\<<foo@example.com>>' => [ '<', { text => 'foo@example.com',
                                     url => 'mailto:foo@example.com' }, '>'],
  '<<foo@example.com>>' => [ '<', { text => 'foo@example.com',
                                    url => 'mailto:foo@example.com' }, '>'],
  '<[foo@example.com](mailto:foo@example.com)>' =>
    [ '<', { text => 'foo@example.com', url => 'mailto:foo@example.com' }, '>'],
  "[this will \[continue to ](work)" =>
    [{ text => "this will [continue to ", url => 'work' }],
  # This edge case might get removed someday; don't depend on it:
  "[this probably [shouldn't ](work)" =>
    [{ text => "this probably [shouldn't ", url => 'work' }],
  # These are not links:
  'just open ['          => ['just open ['],
  '[opened'              => ['[opened'],
  'no [url]'             => ['no [url]'],
  'empty [url]()'        => ['empty [url]()'],
  '[double [open]](url)' => ['[double [open]](url)'],
  # But this is:
  '[double \[open\]](url)' => [{ text => 'double [open]', url => 'url' }],
);

plan tests => @tests/2;

#---------------------------------------------------------------------
# These should succeed:

while (@tests) {
  my $text = shift @tests;

  is_deeply(PostScript::Report::LinkField->parse_value($text),
            shift @tests, $text);
} # end while @tests
