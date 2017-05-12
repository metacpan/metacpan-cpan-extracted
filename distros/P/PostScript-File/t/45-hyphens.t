#! /usr/bin/perl
#---------------------------------------------------------------------
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 1 Nov 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test the convert_hyphens method
#---------------------------------------------------------------------

use strict;
use warnings;

use Test::More;

use PostScript::File 2.00;

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

#---------------------------------------------------------------------
my $hyphen = chr(0x2010);
my $minus  = chr(0x2212);

my @tests = (
  '-'         => '<MINUS>',
  '-s'        => '<HYPHEN>s',
  'but-'      => 'but<HYPHEN>',
  'night-owl' => 'night<HYPHEN>owl',
  '-1'        => '<MINUS>1',
  '2 - 3'     => '2 <MINUS> 3',
  '4-5'       => '4<MINUS>5',
  '6-'        => '6<HYPHEN>',
  '(-7)'      => '(<MINUS>7)',
  '-$8'       => '<MINUS>$8',
  "-\x{20AC}9"=> '<MINUS><U+20AC>9', # euro sign
  "$hyphen $minus -" => '<HYPHEN> <MINUS> <MINUS>',
);

plan tests => @tests / 2;

#---------------------------------------------------------------------
my $ps = PostScript::File->new(reencode => 'cp1252');

while (@tests) {
  my $in = shift @tests;

  is(U($ps->convert_hyphens($in)), shift @tests, U($in));
} # end while @tests
