package Test::Auto::Plugin;

use strict;
use warnings;

use Moo;
use Test::Auto::Types ();

our $VERSION = '0.12'; # VERSION

# ATTRIBUTES

has subtests => (
  is => 'ro',
  isa => Test::Auto::Types::Subtests(),
  required => 1
);

# METHODS

sub tests {
  my ($self, %args) = @_;

  return $self;
}

1;

=encoding utf8

=head1 NAME

Test::Auto::Plugin

=cut

=head1 ABSTRACT

Test-Auto Plugin Class

=cut

=head1 SYNOPSIS

  package Test::Auto::Plugin::Example;

  use Test::More;

  use parent 'Test::Auto::Plugin';

  sub tests {
    my ($self, @args) = @_;

    subtest "testing example plugin", sub {

      ok 1;
    };

    return $self;
  }

  1;

=cut

=head1 DESCRIPTION

This package provides an abstract base class for creating L<Test::Auto>
plugins.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Test::Auto::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 subtests

  subtests(Subtests)

This attribute is read-only, accepts C<(Subtests)> values, and is required.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 tests

  tests(Any @args) : Object

This method is meant to be overridden by the superclass, and should perform
specialized subtests. While not required, ideally this method should return its
invocant.

=over 4

=item tests example #1

  package main;

  use Test::Auto;
  use Test::Auto::Parser;
  use Test::Auto::Subtests;

  my $test = Test::Auto->new(
    't/Test_Auto_Plugin.t'
  );

  my $parser = Test::Auto::Parser->new(
    source => $test
  );

  my $subtests = Test::Auto::Subtests->new(
    parser => $parser
  );

  # Test::Auto::Plugin::ShortDescription
  my $example = $subtests->plugin('ShortDescription');

  $example->tests(length => 200);

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the
L<"license file"|https://github.com/iamalnewkirk/test-auto/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/test-auto/wiki>

L<Project|https://github.com/iamalnewkirk/test-auto>

L<Initiatives|https://github.com/iamalnewkirk/test-auto/projects>

L<Milestones|https://github.com/iamalnewkirk/test-auto/milestones>

L<Issues|https://github.com/iamalnewkirk/test-auto/issues>

=cut
