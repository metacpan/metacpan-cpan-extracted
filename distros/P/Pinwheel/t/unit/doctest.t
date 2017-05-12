#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 44;

use Pinwheel::DocTest;


=begin doctest
Formatting

  >>> 10
  10
  >>> 3.14
  "3.14"
  >>> "hello"
  "hello"
  >>> "abc\ndef\nghi"
  "abc\ndef\nghi"
  >>> [1, 2, "abc", 3]
  [1,2,"abc",3]

Output capture

  >>> print Pinwheel::DocTest::p(10)
  10
  1
  >>> print Pinwheel::DocTest::p(3.14)
  "3.14"
  1
  >>> print Pinwheel::DocTest::p("hello")
  "hello"
  1
  >>> print Pinwheel::DocTest::p("abc\ndef\nghi")
  "abc\ndef\nghi"
  1
  >>> print Pinwheel::DocTest::p([1, 2, "abc", 3])
  [1,2,"abc",3]
  1
  >>> printf("%04d\n", 42)
  0042
  1

Blank lines in output

  >>> print "\nabc\n"
  <BLANKLINE>
  abc
  1
  >>> print "abc\n\ndef\n"
  abc
  <BLANKLINE>
  def
  1

Errors

  >>> die "d'oh!"
  d'oh! at console line ...
  >>> die "d'oh!\nd'oh!"
  d'oh!
  d'oh! at console line ...
=cut


=begin doctest
State preservation

  >>> $x = 10
  >>> $y = 20
  >>> $x + $y
  30

Multi-line input

  >>> sub add {
  ...    $_[0] + $_[1]
  ... }
  undef
  >>> add(1, 2)
  3

Ellipsis to ignore parts of the output

  >>> Pinwheel::DocTest::_expand_ellipsis("abc")
  qr/(?s-xim:^abc$)/
  >>> Pinwheel::DocTest::_expand_ellipsis("abc.*def")
  qr/(?s-xim:^abc\.\*def$)/
  >>> Pinwheel::DocTest::_expand_ellipsis("(abc[def])")
  qr/(?s-xim:^\(abc\[def\]\)$)/
  >>> Pinwheel::DocTest::_expand_ellipsis("abc...def")
  qr/(?s-xim:^abc.*def$)/
  >>> Pinwheel::DocTest::_expand_ellipsis("abc...def...ghi")
  qr/(?s-xim:^abc.*def.*ghi$)/

  >>> "abcdefghi"
  "abc...ghi"
  >>> "abcdefghijklmno"
  "abc...ghi...mno"
  >>> print "abc\ndef\nghi\n"
  abc
  ...
  ghi
  1
  >>> print "abc\ndef\nghi\n"
  abc...ghi
  1
=cut


=begin doctest
Mock objects

  >>> $m = Pinwheel::DocTest::Mock->new("Klass")
  >>> $m->test(1, 2, 3)
  Called Klass->test with [1,2,3]
  undef

  >>> $m = Pinwheel::DocTest::Mock->new("Numbers")
  >>> $m->add(10, 20)
  Called Numbers->add with [10,20]
  undef
  >>> $m->add_returns(sub { $_[0] + $_[1] })
  undef
  >>> $m->const_returns(42)
  undef
  >>> $m->add(10, 20)
  Called Numbers->add with [10,20]
  30
  >>> $m->const
  Called Numbers->const with []
  42

  >>> $m = Pinwheel::DocTest::Mock->new("testfn")
  >>> $m->()
  Called testfn with []
  undef
  >>> $m->(2, 3, 5)
  Called testfn with [2,3,5]
  undef
  >>> $m->returns(42)
  undef
  >>> &$m()
  Called testfn with []
  42
  >>> $m->returns(sub { $_[0] * 2 })
  undef
  >>> $m->(21)
  Called testfn with [21]
  42
=cut


my $x = <<END;
  >>> "This is not a test"
  "This should not be tested"
END


Pinwheel::DocTest::test_file(__FILE__);
