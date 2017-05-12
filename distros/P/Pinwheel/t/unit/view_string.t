#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 26;

use Pinwheel::View::String;
use Pinwheel::DocTest;


sub escape
{
    my $s = shift;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    return $s;
}


=begin doctest

  >>> $a = Pinwheel::View::String->new('a & b', \&escape)
  >>> $b = Pinwheel::View::String->new(' & c', \&escape)

Pinwheel::View::String object does not get escaped

  >>> $a->to_string()
  "a & b"

Appended string gets escaped

  >>> $s = $a . ' & c'
  >>> $s->to_string()
  "a & b &amp; c"

Appended object does not get escaped

  >>> $s = $a . $b
  >>> $s->to_string()
  "a & b & c"

Prepended string gets escaped

  >>> $s = 'x & ' . $a
  >>> $s->to_string()
  "x &amp; a & b"

Prepended object does not get escaped

  >>> $s = Pinwheel::View::String->new('x & ') . $a
  >>> $s->to_string()
  "x & a & b"

String extension gets escaped

  >>> $a .= ' & c'
  ...
  >>> $a->to_string()
  "a & b &amp; c"

Object extension does not get escaped

  >>> $a .= $b
  ...
  >>> $a->to_string()
  "a & b &amp; c & c"

=cut


=begin doctest

  >>> $a = Pinwheel::View::String->new('a & ', \&escape)
  >>> $b = Pinwheel::View::String->new('b & ', \&escape)

Template triggered concatenations

  >>> $a->add('< x')->to_string()
  "a & &lt; x"
  >>> $a->radd('x >')->to_string()
  "x &gt;a & "

  >>> $a->add($b)->to_string()
  "a & b & "
  >>> $a->radd($b)->to_string()
  "b & a & "

=cut


=begin doctest

Pinwheel::View::String object construction

  >>> $a = Pinwheel::View::String->new([['<'], '&', ['>']])
  >>> $b = Pinwheel::View::String->new('&')
  >>> $c = Pinwheel::View::String->new(['<', ['<x&y>'], '>'])
  >>> $s = Pinwheel::View::String->new([$a, ' ', $b, ' ', $c], \&escape)
  >>> $s->to_string()
  "<&amp;> & &lt;<x&y>&gt;"

=cut


Pinwheel::DocTest::test_file(__FILE__);
