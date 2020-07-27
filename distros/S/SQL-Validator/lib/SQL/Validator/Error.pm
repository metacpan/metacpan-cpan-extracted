package SQL::Validator::Error;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Data::Object::Exception';

our $VERSION = '0.01'; # VERSION

# ATTRIBUTES

has 'issues' => (
  is => 'ro',
  isa => 'ArrayRef[InstanceOf["JSON::Validator::Error"]]',
  req => 1,
);

# METHODS

method match(Str $key = '/') {
  $key =~ s/^\/*/\//;

  my @matches = grep {$_->path =~ /^$key/} @{$self->issues};

  return [@matches];
}

method report(Str $key = '/') {
  my $matches = $self->match($key);

  return join "\n", sort map "$_", @$matches;
}

1;
=encoding utf8

=head1 NAME

SQL::Validator::Error - JSON-SQL Schema Validation Error

=cut

=head1 ABSTRACT

JSON-SQL Schema Validation Error

=cut

=head1 SYNOPSIS

  use SQL::Validator::Error;
  use JSON::Validator::Error;

  my $error = SQL::Validator::Error->new(
    issues => [
      JSON::Validator::Error->new('/root', 'not okay'),
      JSON::Validator::Error->new('/node/0', 'not okay'),
      JSON::Validator::Error->new('/node/1', 'not okay')
    ]
  );

=cut

=head1 DESCRIPTION

This package provides a class representation of a error resulting from the
validation of JSON-SQL schemas.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Data::Object::Exception>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 issues

  issues(ArrayRef[InstanceOf["JSON::Validator::Error"]])

This attribute is read-only, accepts C<(ArrayRef[InstanceOf["JSON::Validator::Error"]])> values, and is required.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 match

  match(Str $key = '/') : ArrayRef[Object]

The match method returns the matching issues as an error string.

=over 4

=item match example #1

  # given: synopsis

  my $root = $error->match('root');

=back

=over 4

=item match example #2

  # given: synopsis

  my $nodes = $error->match('node');

=back

=cut

=head2 report

  report(Str $key = '/') : Str

The report method returns the reporting issues as an error string.

=over 4

=item report example #1

  # given: synopsis

  my $report = $error->report('root');

=back

=over 4

=item report example #2

  # given: synopsis

  my $report = $error->report('node');

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/sql-validator/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/sql-validator/wiki>

L<Project|https://github.com/iamalnewkirk/sql-validator>

L<Initiatives|https://github.com/iamalnewkirk/sql-validator/projects>

L<Milestones|https://github.com/iamalnewkirk/sql-validator/milestones>

L<Contributing|https://github.com/iamalnewkirk/sql-validator/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/sql-validator/issues>

=cut