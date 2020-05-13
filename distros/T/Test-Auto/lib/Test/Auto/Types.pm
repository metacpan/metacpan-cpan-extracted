package Test::Auto::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;

BEGIN {
  extends 'Types::Standard';
}

our $VERSION = '0.12'; # VERSION

declare 'Data',
  as InstanceOf['Test::Auto::Data'];

declare 'Document',
  as InstanceOf['Test::Auto::Document'];

declare 'Parser',
  as InstanceOf['Test::Auto::Parser'];

declare 'Plugin',
  as InstanceOf['Test::Auto::Plugin'];

declare 'Source',
  as InstanceOf['Test::Auto'];

declare 'Strings',
  as ArrayRef[Str];

declare 'Subtests',
  as InstanceOf['Test::Auto::Subtests'];

1;

=encoding utf8

=head1 NAME

Test::Auto::Types

=cut

=head1 ABSTRACT

Test-Auto Type Constraints

=cut

=head1 SYNOPSIS

  package main;

  use Test::Auto::Types;

  1;

=cut

=head1 DESCRIPTION

This package provides type constraints for L<Test::Auto>.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Types::Standard>

=cut

=head1 CONSTRAINTS

This package declares the following type constraints:

=cut

=head2 parser

  Parser

This type is defined in the L<Test::Auto::Types> library.

=over 4

=item parser parent

  Object

=back

=over 4

=item parser composition

  InstanceOf['Test::Auto::Parser']

=back

=over 4

=item parser example #1

  require Test::Auto;
  require Test::Auto::Parser;

  my $test = Test::Auto->new('t/Test_Auto.t');
  my $parser = Test::Auto::Parser->new(source => $test);

=back

=cut

=head2 source

  Source

This type is defined in the L<Test::Auto::Types> library.

=over 4

=item source parent

  Object

=back

=over 4

=item source composition

  InstanceOf['Test::Auto']

=back

=over 4

=item source example #1

  require Test::Auto;

  my $test = Test::Auto->new('t/Test_Auto.t');

=back

=cut

=head2 strings

  Strings

This type is defined in the L<Test::Auto::Types> library.

=over 4

=item strings composition

  ArrayRef[Str]

=back

=over 4

=item strings example #1

  ['abc', 123]

=back

=cut

=head2 subtests

  Subtests

This type is defined in the L<Test::Auto::Types> library.

=over 4

=item subtests parent

  Object

=back

=over 4

=item subtests composition

  InstanceOf['Test::Auto::Subtests']

=back

=over 4

=item subtests example #1

  require Test::Auto;
  require Test::Auto::Parser;
  require Test::Auto::Subtests;

  my $test = Test::Auto->new('t/Test_Auto.t');
  my $parser = Test::Auto::Parser->new(source => $test);
  my $subs = Test::Auto::Subtests->new(parser => $parser);

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
