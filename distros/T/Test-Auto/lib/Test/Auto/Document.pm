package Test::Auto::Document;

use Data::Object 'Class';

use Type::Registry;
use Test::More;

our $VERSION = '0.04'; # VERSION

has content => (
  is => 'ro',
  isa => 'ArrayRef[Str]'
);

has template => (
  is => 'ro',
  isa => 'Maybe[Str]',
  def => $ENV{TEST_AUTO_TEMPLATE}
);

has parser => (
  is => 'ro',
  isa => 'InstanceOf["Test::Auto::Parser"]',
  req => 1
);

# BUILD

method BUILD($args) {
  # build content from parser data
  $self->{content} = $self->construct if !$args->{content};

  return $self;
}

# METHODS

method construct() {
  my $content = [];

  push @$content, $self->construct_name;
  push @$content, $self->construct_abstract;
  push @$content, $self->construct_synopsis;
  push @$content, $self->construct_description;
  push @$content, $self->construct_headers;
  push @$content, $self->construct_inherits;
  push @$content, $self->construct_integrates;
  push @$content, $self->construct_libraries;
  push @$content, $self->construct_scenarios;
  push @$content, $self->construct_attributes;
  push @$content, $self->construct_functions;
  push @$content, $self->construct_routines;
  push @$content, $self->construct_methods;
  push @$content, $self->construct_footers;

  return $content;
}


method construct_name() {
  my $parser = $self->parser;
  my $name = $parser->name;

  return $self->head1('name', $name);
}

method construct_abstract() {
  my $parser = $self->parser;
  my $abstract = $parser->abstract;

  return $self->head1('abstract', $abstract);
}

method construct_synopsis() {
  my $parser = $self->parser;
  my $synopsis = $parser->synopsis;

  return $self->head1('synopsis', $synopsis);
}

method construct_description() {
  my $parser = $self->parser;
  my $description = $parser->description;

  return $self->head1('description', $description);
}

method construct_inherits() {
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

method construct_integrates() {
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

method construct_libraries() {
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

method construct_scenarios() {
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

method construct_scenarios_item($name) {
  my $parser = $self->parser;
  my $scenarios = $parser->scenarios;
  my $scenario = $scenarios->{$name} or return ();

  my $usage = $scenario->{usage};
  my $example = $scenario->{example}[0];

  return $self->head2($name, [@$example, "", @$usage]);
}

method construct_attributes() {
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

method construct_attributes_item($name) {
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

method construct_headers() {
  my $parser = $self->parser;
  my $headers = $parser->headers;

  return () if !$headers || !@$headers;

  return join("\n", "", @$headers);
}

method construct_functions() {
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

method construct_functions_item($name) {
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

method construct_routines() {
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

method construct_routines_item($name) {
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

method construct_methods() {
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

method construct_methods_item($name) {
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

method construct_footers() {
  my $parser = $self->parser;
  my $footers = $parser->footers;

  return () if !$footers || !@$footers;

  return join("\n", "", @$footers);
}

method render() {
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

method templated($content) {
  my $template = $self->template || $ENV{TEST_AUTO_TEMPLATE};

  return $content unless $template;

  open my $fh, "<", $template or raise "Can't open $template: $!";

  my $output = join "", <$fh>;

  close $fh;

  $output =~ s/\{content\}/$content/;

  return $output;
}

method over(@items) {
  return join("\n", "", "=over 4", "", @items, "=back");
}

method item($name, $data) {
  return ("=item $name\n", "$data\n");
}

method head1($name, $data) {
  return join("\n", "", "=head1 \U$name", "", @{$data}, "", "=cut");
}

method head2($name, $data) {
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

L<Data::Object::Library>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 content

  content(ArrayRef[Str])

This attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

=cut

=head2 parser

  parser(InstanceOf["Test::Auto::Parser"])

This attribute is read-only, accepts C<(InstanceOf["Test::Auto::Parser"])> values, and is required.

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

L<Project|https://github.com/iamalnewkirk/test-auto>

L<Milestones|https://github.com/iamalnewkirk/test-auto/milestones>

L<Issues|https://github.com/iamalnewkirk/test-auto/issues>

=cut
