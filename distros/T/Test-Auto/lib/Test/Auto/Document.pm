package Test::Auto::Document;

use strict;
use warnings;

use Moo;
use Test::Auto::Types ();
use Test::More;
use Type::Registry;

require Carp;

our $VERSION = '0.12'; # VERSION

# ATTRIBUTES

has content => (
  is => 'ro',
  isa => Test::Auto::Types::Strings()
);

has template => (
  is => 'ro',
  isa => Test::Auto::Types::Maybe([Test::Auto::Types::Str()]),
  default => $ENV{TEST_AUTO_TEMPLATE}
);

has parser => (
  is => 'ro',
  isa => Test::Auto::Types::Parser(),
  required => 1
);

# BUILD

sub BUILD {
  my ($self, $args) = @_;

  # build content from parser data
  $self->{content} = $self->construct if !$args->{content};

  return $self;
}

# METHODS

sub construct {
  my ($self) = @_;

  my $content = [];

  push @$content, $self->construct_name;
  push @$content, $self->construct_abstract;
  push @$content, $self->construct_synopsis;
  push @$content, $self->construct_description;
  push @$content, $self->construct_headers;
  push @$content, $self->construct_inherits;
  push @$content, $self->construct_integrates;
  push @$content, $self->construct_libraries;
  push @$content, $self->construct_constraints;
  push @$content, $self->construct_scenarios;
  push @$content, $self->construct_attributes;
  push @$content, $self->construct_functions;
  push @$content, $self->construct_routines;
  push @$content, $self->construct_methods;
  push @$content, $self->construct_footers;

  return $content;
}

sub construct_name {
  my ($self) = @_;

  my $parser = $self->parser;
  my $name = $parser->name;

  if (my $tagline = $parser->tagline) {
    $name->[0] = $name->[0] .' - '. $tagline->[0] if @$tagline;
  }

  return $self->head1('name', $name);
}

sub construct_abstract {
  my ($self) = @_;

  my $parser = $self->parser;
  my $abstract = $parser->abstract;

  return $self->head1('abstract', $abstract);
}

sub construct_synopsis {
  my ($self) = @_;

  my $parser = $self->parser;
  my $synopsis = $parser->synopsis;

  return $self->head1('synopsis', $synopsis);
}

sub construct_description {
  my ($self) = @_;

  my $parser = $self->parser;
  my $description = $parser->description;

  return $self->head1('description', $description);
}

sub construct_inherits {
  my ($self) = @_;

  my $parser = $self->parser;
  my $inherits = $parser->inherits;

  return () if !$inherits || !@$inherits;

  my @content;

  push @content, $self->head1('inherits', [
    "This package inherits behaviors from:",
    "", join "\n\n", map "L<$_>", @$inherits
  ]);

  return join("\n", @content);
}

sub construct_integrates {
  my ($self) = @_;

  my $parser = $self->parser;
  my $integrates = $parser->integrates;

  return () if !$integrates || !@$integrates;

  my @content;

  push @content, $self->head1('integrates', [
    "This package integrates behaviors from:",
    "", join "\n\n", map "L<$_>", @$integrates
  ]);

  return join("\n", @content);
}

sub construct_libraries {
  my ($self) = @_;

  my $parser = $self->parser;
  my $libraries = $parser->libraries;

  return () if !$libraries || !@$libraries;

  my @content;

  push @content, $self->head1('libraries', [
    "This package uses type constraints from:",
    "", join "\n\n", map "L<$_>", @$libraries
  ]);

  return join("\n", @content);
}

sub construct_constraints {
  my ($self) = @_;

  my $parser = $self->parser;
  my $types = $parser->types;

  return () if !$types || !%$types;

  my @content;

  push @content, $self->head1('constraints', [
    "This package declares the following type constraints:",
  ]);

  my @order = sort keys %$types;

  push @content, $self->construct_constraints_item($_) for @order;

  return join("\n", @content);
}

sub construct_constraints_item {
  my ($self, $name) = @_;

  my $label = lc $name;
  my $parser = $self->parser;
  my $types = $parser->types;
  my $type = $types->{$name} or return ();

  my @content;

  my $usage = $type->{usage}[0];
  my $library = $type->{library}[0] if $type->{library};
  my $composite = $type->{composite}[0] if $type->{composite};
  my $parent = $type->{parent}[0] if $type->{parent};

  push @content, @$usage;

  if ($library) {
    $library = $library->[0];
    push @content, "", "This type is defined in the L<$library> library.";
  }

  if ($parent) {
    push @content, $self->over($self->item(
      "$label parent", join "\n", @$parent
    ));
  }

  if ($composite) {
    push @content, $self->over($self->item(
      "$label composition", join "\n", @$composite
    ));
  }

  if (my $coercions = $type->{coercions}) {
    for my $number (sort keys %{$coercions}) {
      my $coercion = $coercions->{$number}[0];
      push @content, $self->over($self->item(
        "$label coercion #$number", join "\n", @$coercion
      ));
    }
  }

  if (my $examples = $type->{examples}) {
    for my $number (sort keys %{$examples}) {
      my $example = $examples->{$number}[0];
      push @content, $self->over($self->item(
        "$label example #$number", join "\n", @$example
      ));
    }
  }

  return $self->head2($name, [@content]);
}

sub construct_scenarios {
  my ($self) = @_;

  my $parser = $self->parser;
  my $scenarios = $parser->scenarios;

  return () if !$scenarios || !%$scenarios;

  my @content;

  push @content, $self->head1('scenarios', [
    "This package supports the following scenarios:"
  ]);

  my @order = sort keys %$scenarios;

  push @content, $self->construct_scenarios_item($_) for @order;

  return join("\n", @content);
}

sub construct_scenarios_item {
  my ($self, $name) = @_;

  my $parser = $self->parser;
  my $scenarios = $parser->scenarios;
  my $scenario = $scenarios->{$name} or return ();

  my $usage = $scenario->{usage};
  my $example = $scenario->{example}[0];

  return $self->head2($name, [@$example, "", @$usage]);
}

sub construct_attributes {
  my ($self) = @_;

  my $parser = $self->parser;
  my $attributes = $parser->attributes;

  return () if !$attributes || !@$attributes;

  my @content;

  push @content, $self->head1('attributes', [
    "This package has the following attributes:"
  ]),
  join "\n", map $self->construct_attributes_item($_),
    sort keys %{$parser->stash('attributes')};

  return join("\n", @content);
}

sub construct_attributes_item {
  my ($self, $name) = @_;

  my $parser = $self->parser;
  my $attributes = $parser->stash('attributes');
  my $attribute = $attributes->{$name} or return ();

  my $is = $attribute->{is};
  my $type = $attribute->{type};
  my $presence = $attribute->{presence};

  $is = "read-only" if $is eq 'ro';
  $is = "read-write" if $is eq 'rw';

  $presence = "required" if $presence eq 'req';
  $presence = "optional" if $presence eq 'opt';

  return $self->head2($name, [
    "  $name($type)\n",
    "This attribute is $is, accepts C<($type)> values, and is $presence."
  ]);
}

sub construct_headers {
  my ($self) = @_;

  my $parser = $self->parser;
  my $headers = $parser->headers;

  return () if !$headers || !@$headers;

  return join("\n", "", @$headers);
}

sub construct_functions {
  my ($self) = @_;

  my $parser = $self->parser;
  my $functions = $parser->functions;

  return () if !$functions || !%$functions;

  my @content;

  push @content, $self->head1('functions', [
    "This package implements the following functions:"
  ]);

  my @order = sort keys %$functions;

  push @content, $self->construct_functions_item($_) for @order;

  return join("\n", @content);
}

sub construct_functions_item {
  my ($self, $name) = @_;

  my $parser = $self->parser;
  my $functions = $parser->functions;
  my $function = $functions->{$name} or return ();

  my @examples;

  my $usage = $function->{usage}[0];
  my $signature = $function->{signature}[0];

  for my $number (sort keys %{$function->{examples}}) {
    my $example = $function->{examples}{$number}[0];
    my @content = ("$name example #$number", join "\n", @$example);
    push @examples, $self->over($self->item(@content));
  }

  return $self->head2($name, ["  $$signature[0]", "", @$usage, @examples]);
}

sub construct_routines {
  my ($self) = @_;

  my $parser = $self->parser;
  my $routines = $parser->routines;

  return () if !$routines || !%$routines;

  my @content;

  push @content, $self->head1('routines', [
    "This package implements the following routines:"
  ]);

  my @order = sort keys %$routines;

  push @content, $self->construct_routines_item($_) for @order;

  return join("\n", @content);
}

sub construct_routines_item {
  my ($self, $name) = @_;

  my $parser = $self->parser;
  my $routines = $parser->routines;
  my $routine = $routines->{$name} or return ();

  my @examples;

  my $usage = $routine->{usage}[0];
  my $signature = $routine->{signature}[0];

  for my $number (sort keys %{$routine->{examples}}) {
    my $example = $routine->{examples}{$number}[0];
    my @content = ("$name example #$number", join "\n", @$example);
    push @examples, $self->over($self->item(@content));
  }

  return $self->head2($name, ["  $$signature[0]", "", @$usage, @examples]);
}

sub construct_methods {
  my ($self) = @_;

  my $parser = $self->parser;
  my $methods = $parser->methods;

  return () if !$methods || !%$methods;

  my @content;

  push @content, $self->head1('methods', [
    "This package implements the following methods:"
  ]);

  my @order = sort keys %$methods;

  push @content, $self->construct_methods_item($_) for @order;

  return join("\n", @content);
}

sub construct_methods_item {
  my ($self, $name) = @_;

  my $parser = $self->parser;
  my $methods = $parser->methods;
  my $method = $methods->{$name} or return ();

  my @examples;

  my $usage = $method->{usage}[0];
  my $signature = $method->{signature}[0];

  for my $number (sort keys %{$method->{examples}}) {
    my $example = $method->{examples}{$number}[0];
    my @content = ("$name example #$number", join "\n", @$example);
    push @examples, $self->over($self->item(@content));
  }

  return $self->head2($name, ["  $$signature[0]", "", @$usage, @examples]);
}

sub construct_footers {
  my ($self) = @_;

  my $parser = $self->parser;
  my $footers = $parser->footers;

  return () if !$footers || !@$footers;

  return join("\n", "", @$footers);
}

sub render {
  my ($self) = @_;

  my $content = $self->content;

  $content = join "\n", @$content;
  $content =~ s/^\n+|\n+$//g;

  # unescape nested pod
  $content =~ s/^\+=\s*(.+?)\s*(\r?\n)/=$1$2\n/mg;
  $content =~ s/^\+=cut\r?\n?$/=cut/m;

  # process template (if applicable)
  $content = $self->templated($content);

  # add leading newline to assist coalescing
  return "\n$content";
}

sub templated {
  my ($self, $content) = @_;

  my $template = $self->template || $ENV{TEST_AUTO_TEMPLATE};

  return $content unless $template;

  open my $fh, "<", $template or Carp::confess "Can't open $template: $!";

  my $output = join "", <$fh>;

  close $fh;

  $output =~ s/\{content\}/$content/;

  return $output;
}

sub over {
  my ($self, @items) = @_;

  return join("\n", "", "=over 4", "", @items, "=back");
}

sub item {
  my ($self, $name, $data) = @_;

  return ("=item $name\n", "$data\n");
}

sub head1 {
  my ($self, $name, $data) = @_;

  return join("\n", "", "=head1 \U$name", "", @{$data}, "", "=cut");
}

sub head2 {
  my ($self, $name, $data) = @_;

  return join("\n", "", "=head2 \L$name", "", @{$data}, "", "=cut");
}

1;

=encoding utf8

=head1 NAME

Test::Auto::Document

=cut

=head1 ABSTRACT

Documentation Generator

=cut

=head1 SYNOPSIS

  package main;

  use Test::Auto;
  use Test::Auto::Parser;
  use Test::Auto::Document;

  my $test = Test::Auto->new(
    't/Test_Auto.t'
  );

  my $parser = Test::Auto::Parser->new(
    source => $test
  );

  my $doc = Test::Auto::Document->new(
    parser => $parser
  );

  # render documentation

  # $doc->render

=cut

=head1 DESCRIPTION

This package use the L<Test::Auto::Parser> object to generate a valid Perl 5
POD document.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Test::Auto::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 content

  content(ArrayRef[Str])

This attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

=cut

=head2 parser

  parser(Parser)

This attribute is read-only, accepts C<(Parser)> values, and is required.

=cut

=head2 template

  template(Maybe[Str])

This attribute is read-only, accepts C<(Maybe[Str])> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 render

  render() : Str

This method returns a string representation of a valid POD document. You can
also provide a template to wrap the generated document by passing it to the
constructor or specifying it in the C<TEST_AUTO_TEMPLATE> environment variable.

=over 4

=item render example #1

  # given: synopsis

  my $rendered = $doc->render;

=back

=over 4

=item render example #2

  # given: synopsis

  $ENV{TEST_AUTO_TEMPLATE} = './t/Test_Template.pod';

  # where ./t/Test_Template.pod has a {content} placeholder

  my $rendered = $doc->render;

  undef $ENV{TEST_AUTO_TEMPLATE};

  $rendered;

=back

=over 4

=item render example #3

  # given: synopsis

  my $tmpl = Test::Auto::Document->new(
    parser => $parser,
    template => './t/Test_Template.pod'
  );

  my $rendered = $tmpl->render;

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
