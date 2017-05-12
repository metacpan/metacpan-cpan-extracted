#! /usr/bin/perl
#---------------------------------------------------------------------
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 12 Oct 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test the pstr function/method
#---------------------------------------------------------------------

use strict;
use warnings;

use Test::More;

use PostScript::File 'pstr';

#---------------------------------------------------------------------
my %char = qw(
  8208 <HYPHEN>
  8722 <MINUS>
);

sub U
{
  join '', map {
    $char{$_} || ($_ < 0x7F ? chr($_) : sprintf '<U+%04X>', $_)
  } unpack 'U*', $_[0];
} # end U

#=====================================================================
#  Run the tests.

my @standardTests  = (
  'Hello, world'  => '(Hello, world)',
  'is ('          => '(is \()',
  "has\n newline" => '(has\n newline)',
  'xxxx ' x 100   => '(' . ('xxxx ' x 48) . "\\\n" .
                           ('xxxx ' x 48) . "x\\\nxxx " .
                           ('xxxx ' x 3) . ')',
  'a         ' x 50 => '(' . ('a         ' x 24) . "\\\n" .
                             ('a         ' x 24) . "a\\\n\\         " .
                             ('a         ' x 1) . ')',
  (grep { $_ } split /\s+/, <<'END BACKSLASHES'),
     has\backslash      (has\\backslash)
     double\\backslash  (double\\\\backslash)
END BACKSLASHES
  "have\n newline"   => '(have\n newline)',
  "have\r\n CRLF"    => '(have\r\n CRLF)',
  "have\t tab"       => '(have\t tab)',
  "have\b backspace" => '(have\b backspace)',
  "have\f form feed" => '(have\f form feed)',
  "have () parens"   => '(have \(\) parens)',
); # end @standardTests

my $hyphen = chr(0x2010);
my $minus  = chr(0x2212);

my @hyphenTests = (
  @standardTests,
  'non-invasive'     => '(non<HYPHEN>invasive)',
  'black-and-white'  => '(black<HYPHEN>and<HYPHEN>white)',
  '-'                => '(<MINUS>)',
  '-s'               => '(<HYPHEN>s)',
  'but-'             => '(but<HYPHEN>)',
  'night-owl'        => '(night<HYPHEN>owl)',
  '-1'               => '(<MINUS>1)',
  '2 - 3'            => '(2 <MINUS> 3)',
  '4-5'              => '(4<MINUS>5)',
  '6-'               => '(6<HYPHEN>)',
  "$hyphen $minus -" => '(<HYPHEN> <MINUS> <MINUS>)',
); # end @hyphenTests

plan tests => 1 + @standardTests + @hyphenTests / 2;

#---------------------------------------------------------------------
# Test pstr as exported subroutine:

my @tests = @standardTests;

while (@tests) {
  my $in = shift @tests;

  (my $name = $in) =~ s/[\b\s]+/ /g;
  $name = substr($name, 0, 50);

  is(pstr($in), shift @tests, $name);
} # end while @tests

#---------------------------------------------------------------------
# Test pstr as class method:

@tests = @standardTests;

while (@tests) {
  my $in = shift @tests;

  (my $name = $in) =~ s/[\b\s]+/ /g;
  $name = substr($name, 0, 50);

  is(PostScript::File->pstr($in), shift @tests, "class method $name");
} # end while @tests

#---------------------------------------------------------------------
# Test pstr as class method with nowrap:

my $text = 'xxxx ' x 60;
is(PostScript::File->pstr($text, 1), "($text)", "class method with nowrap");

#---------------------------------------------------------------------
# Test pstr as object method with hyphen processing:

@tests = @hyphenTests;

my $ps = PostScript::File->new(reencode => 'cp1252');

while (@tests) {
  my $in = shift @tests;
  my $out = shift @tests;

  (my $name = $out) =~ s/[\b\s]+/ /g;
  $name = substr($name, 0, 50);

  is(U($ps->pstr($in)), $out, "hypen $name");
} # end while @tests
