#!/usr/bin/env perl
use warnings;
use strict;
use YAML;
use Test::More tests => 1;
use Test::Differences;

package Foo;
use Pod::Generated::Attributes;
our $__DOC : Purpose(test class for demonstrating doc attributes) :
  Author(Marcel Gruenauer <marcel@cpan.org>);
our $VERSION = '0.05';
our %blah : Purpose(the blah hash);
our $say : Purpose(what we say) : Default(abc);

sub new : Purpose(constructs a %p object) : Returns(the %p object) :
  Throws(exception 1) : Throws(exception 2) : Throws(exception 3) {
    bless {}, shift;
}

sub say : Purpose(prints its arguments, appending a newline) :
  Param(@text; the text to be printed) : Deprecated(use Perl6::Say instead) {
    my $self = shift;
    print @_, "\n";
}

package main;
my $expected = Load(<<'EOYAML');
Foo:
  CODE:
    new:
      purpose:
        - constructs a Foo object
      returns:
        - the Foo object
      throws:
        - exception 1
        - exception 2
        - exception 3
    say:
      deprecated:
        - use Perl6::Say instead
      param:
        - '@text; the text to be printed'
      purpose:
        - 'prints its arguments, appending a newline'
  HASH:
    blah:
      purpose:
        - the blah hash
  SCALAR:
    __DOC:
      purpose:
        - test class for demonstrating doc attributes
      author:
        - 'Marcel Gruenauer <marcel@cpan.org>'
    say:
      default:
        - abc
      purpose:
        - what we say
EOYAML
eq_or_diff({ Pod::Generated::doc() }, $expected, 'doc hash');
