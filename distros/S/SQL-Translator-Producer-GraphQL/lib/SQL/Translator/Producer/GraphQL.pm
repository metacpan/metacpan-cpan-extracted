package SQL::Translator::Producer::GraphQL;
use 5.008001;
use strict;
use warnings;
use SQL::Translator::Producer::DBIx::Class::File;
use GraphQL::Plugin::Convert::DBIC;

our $VERSION = "0.03";

my $dbic_schema_class_track = 'CLASS00000';
sub produce {
  my $translator = shift;
  my $schema = $translator->schema;
  my $dbic_schema_class = ++$dbic_schema_class_track;
  my $dbic_translator = bless { %$translator }, ref $translator;
  $dbic_translator->producer_args({ prefix => $dbic_schema_class });
  eval SQL::Translator::Producer::DBIx::Class::File::produce($dbic_translator);
  die "Failed to make DBIx::Class::Schema: $@" if $@;
  my $converted = GraphQL::Plugin::Convert::DBIC->to_graphql(
    sub { $dbic_schema_class->connect }
  );
  $converted->{schema}->to_doc;
}

=encoding utf-8

=head1 NAME

SQL::Translator::Producer::GraphQL - GraphQL schema producer for SQL::Translator

=begin markdown

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/graphql-perl/SQL-Translator-Producer-GraphQL.svg?branch=master)](https://travis-ci.org/graphql-perl/SQL-Translator-Producer-GraphQL) |

[![CPAN version](https://badge.fury.io/pl/SQL-Translator-Producer-GraphQL.svg)](https://metacpan.org/pod/SQL::Translator::Producer::GraphQL)

=end markdown

=head1 SYNOPSIS

  use SQL::Translator;
  use SQL::Translator::Producer::GraphQL;
  my $t = SQL::Translator->new( parser => '...' );
  $t->producer('GraphQL');
  $t->translate;

=head1 DESCRIPTION

This module will produce a L<GraphQL::Schema> from the given
L<SQL::Translator::Schema>. It does this by first
turning it into a L<DBIx::Class::Schema> using
L<SQL::Translator::Producer::DBIx::Class::File>, then passing it to
L<GraphQL::Plugin::Convert::DBIC/to_graphql>.

=head1 ARGUMENTS

Currently none.

=head1 DEBUGGING

To debug, set environment variable C<GRAPHQL_DEBUG> to a true value.

=head1 AUTHOR

Ed J, C<< <etj at cpan.org> >>

Based heavily on L<SQL::Translator::Producer::DBIxSchemaDSL>.

=head1 LICENSE

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
