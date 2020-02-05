package Test::Auto::Parser;

use Data::Object 'Class';

use Data::Object 'WithStashable';

our $VERSION = '0.04'; # VERSION

has name => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  opt => 1
);

has abstract => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  opt => 1
);

has synopsis => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  opt => 1
);

has includes => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  opt => 1
);

has description => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  opt => 1
);

has inherits => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  opt => 1
);

has integrates => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  opt => 1
);

has attributes => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  opt => 1
);

has libraries => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  opt => 1
);

has headers => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  opt => 1
);

has footers => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  opt => 1
);

has source => (
  is => 'ro',
  isa => 'InstanceOf["Test::Auto"]',
  req => 1
);

# BUILD

around BUILD($args) {
  $self->$orig($args);

  my $source = $self->source->data;

  $self->build_name;
  $self->build_abstract;
  $self->build_synopsis;
  $self->build_includes;
  $self->build_description;
  $self->build_inherits;
  $self->build_integrates;
  $self->build_attributes;
  $self->build_libraries;
  $self->build_headers;
  $self->build_footers;
  $self->build_scenarios;
  $self->build_methods;
  $self->build_functions;
  $self->build_routines;

  return $self;
}

# METHODS

method build_name() {
  $self->parse_name;
  $self->check_name or raise 'build name failed';

  return $self->name;
}

method parse_name() {
  my $source = $self->source->data;

  return $self->{name} = $source->content('name');
}

method check_name() {
  my $name = $self->name;

  return 1 if !$name;

  return 0 if $name->[0] =~ /[^\w\'\:']/;

  return 1;
}

method build_abstract() {
  $self->parse_abstract;
  $self->check_abstract or raise 'build abstract failed';

  return $self->abstract;
}

method parse_abstract() {
  my $source = $self->source->data;

  return $self->{abstract} = $source->content('abstract');
}

method check_abstract() {
  my $abstract = $self->abstract;

  return 1 if !$abstract;

  return 0 if $abstract->[0] !~ /\w/;

  return 1;
}

method build_synopsis() {
  $self->parse_synopsis;
  $self->check_synopsis or raise 'build synopsis failed';

  return $self->synopsis;
}

method parse_synopsis() {
  my $source = $self->source->data;

  return $self->{synopsis} = $source->content('synopsis');
}

method check_synopsis() {
  my $synopsis = $self->synopsis;

  return 1 if !$synopsis;

  return 0 if $synopsis->[0] !~ /\w/;

  return 1;
}

method build_includes() {
  $self->parse_includes;
  $self->check_includes or raise 'build includes failed';

  return $self->includes;
}

method parse_includes() {
  my $source = $self->source->data;

  return $self->{includes} = $source->content('includes');
}

method check_includes() {
  my $includes = $self->includes;

  return 1 if !$includes;

  for my $include (map { [split /\s*:\s*/]  } grep {length} @$includes) {
    next if $include->[0] eq 'function';
    next if $include->[0] eq 'routine';
    next if $include->[0] eq 'method';

    return 0;
  }

  return 1;
}

method build_description() {
  $self->parse_description;
  $self->check_description or raise 'build description failed';

  return $self->description;
}

method parse_description() {
  my $source = $self->source->data;

  return $self->{description} = $source->content('description');
}

method check_description() {
  my $description = $self->description;

  return 0 if !$description;
  return 1;
}

method build_inherits() {
  $self->parse_inherits;
  $self->check_inherits or raise 'build inherits failed';

  return $self->inherits;
}

method parse_inherits() {
  my $source = $self->source->data;

  return $self->{inherits} = $source->content('inherits');
}

method check_inherits() {
  my $inherits = $self->inherits;

  return 1 if !$inherits;

  for my $inherit (@$inherits) {
    return 0 if $inherit =~ /[^\w\'\:']/;
  }

  return 1;
}

method build_integrates() {
  $self->parse_integrates;
  $self->check_integrates or raise 'build integrates failed';

  return $self->integrates;
}

method parse_integrates() {
  my $source = $self->source->data;

  return $self->{integrates} = $source->content('integrates');
}

method check_integrates() {
  my $integrates = $self->integrates;

  return 1 if !$integrates;

  for my $integrate (@$integrates) {
    return 0 if $integrate =~ /[^\w\'\:']/;
  }

  return 1;
}

method build_attributes() {
  $self->parse_attributes;
  $self->check_attributes or raise 'build attributes failed';

  return $self->attributes;
}

method parse_attributes() {
  my $source = $self->source->data;
  my $lines = $source->content('attributes');

  my $attributes = {};

  for my $line (@$lines) {
    my ($name, $is, $presence, $type) = map {split /,\s*/}
      ($line =~ /(\w+)\s*\:\s*(.*)/);

    $attributes->{$name} = {is => $is, presence => $presence, type => $type};
  }

  $self->stash(attributes => $attributes);

  return $self->{attributes} = $lines;
}

method check_attributes() {
  my $attributes = $self->attributes;

  return 1 if !@$attributes;

  my $stashed = $self->stash('attributes');

  for my $name (keys %$stashed) {
    return 0 if !$stashed->{$name}{is};
    return 0 if !(
      $stashed->{$name}{is} eq 'ro' ||
      $stashed->{$name}{is} eq 'rw'
    );
    return 0 if !$stashed->{$name}{presence};
    return 0 if !(
      $stashed->{$name}{presence} eq 'req' ||
      $stashed->{$name}{presence} eq 'opt'
    );
    return 0 if !$stashed->{$name}{type};
  }

  return 1;
}

method build_libraries() {
  $self->parse_libraries;
  $self->check_libraries or raise 'build libraries failed';

  return $self->libraries;
}

method parse_libraries() {
  my $source = $self->source->data;

  return $self->{libraries} = $source->content('libraries');
}

method check_libraries() {
  my $libraries = $self->libraries;

  return 1 if !$libraries;

  for my $library (@$libraries) {
    return 0 if $library =~ /[^\w\'\:']/;
  }

  return 1;
}

method build_headers() {
  $self->parse_headers;
  $self->check_headers or raise 'build headers failed';

  return $self->headers;
}

method parse_headers() {
  my $source = $self->source->data;

  return $self->{headers} = $source->content('headers');
}

method check_headers() {
  my $headers = $self->headers;

  return 1 if !$headers;

  return 0 unless scalar @$headers;

  return 1;
}

method build_footers() {
  $self->parse_footers;
  $self->check_footers or raise 'build footers failed';

  return $self->footers;
}

method parse_footers() {
  my $source = $self->source->data;

  return $self->{footers} = $source->content('footers');
}

method check_footers() {
  my $footers = $self->footers;

  return 1 if !$footers;

  return 0 unless scalar @$footers;

  return 1;
}

method build_scenarios() {
  $self->parse_scenarios;
  $self->check_scenarios or raise 'build scenarios failed';

  return $self->stash('scenarios');
}

method parse_scenarios() {
  my $source = $self->source->data;

  my $scenarios = {};

  for my $metadata (@{$source->list('scenario')}) {
    if (my $content = $source->contents("example", $metadata->{name})) {
      next if !@$content;

      my $usage = $metadata->{data};
      $scenarios->{$metadata->{name}} = {
        usage => $usage,
        example => $content
      };
    }
  }

  return $self->stash(scenarios => $scenarios);
}

method check_scenarios() {
  my $scenarios = $self->stash('scenarios');

  return 1 if !%$scenarios;

  while (my($key, $val) = each(%$scenarios)) {
    return 0 unless $val->{usage};
    return 0 unless $val->{example};
  }

  return 1;
}

method build_methods() {
  return if !$self->includes;

  $self->parse_methods;
  $self->check_methods or raise 'build methods failed';

  return $self->stash('methods');
}

method parse_methods() {
  my $source = $self->source->data;

  my $methods = {};

  for my $include (map { [split /\s*:\s*/]  } grep {length} @{$self->includes}) {
    next if $include->[0] ne 'method';

    my $item = {};
    my $name = $include->[1];

    $item->{usage} = $source->contents('method', $name);
    $item->{signature} = $source->contents('signature', $name);

    my $index = 1;
    while (my $content = $source->contents("example-$index", $name)) {
      last if !@$content;

      $item->{examples}{$index} = $content;
      $index++;
    }

    $methods->{$name} = $item;
  }

  return $self->stash(methods => $methods);
}

method check_methods() {
  my $methods = $self->stash('methods');

  return 1 if !%$methods;

  while (my($key, $val) = each(%$methods)) {
    return 0 unless $val->{usage};
    return 0 unless $val->{signature};
    return 0 unless $val->{examples};
  }

  return 1;
}

method build_functions() {
  return if !$self->includes;

  $self->parse_functions;
  $self->check_functions or raise 'build functions failed';

  return $self->stash('functions');
}

method parse_functions() {
  my $source = $self->source->data;

  my $functions = {};

  for my $include (map { [split /\s*:\s*/]  } grep {length} @{$self->includes}) {
    next if $include->[0] ne 'function';

    my $item = {};
    my $name = $include->[1];

    $item->{usage} = $source->contents('function', $name);
    $item->{signature} = $source->contents('signature', $name);

    my $index = 1;
    while (my $content = $source->contents("example-$index", $name)) {
      last if !@$content;

      $item->{examples}{$index} = $content;
      $index++;
    }

    $functions->{$name} = $item;
  }

  return $self->stash(functions => $functions);
}

method check_functions() {
  my $functions = $self->stash('functions');

  return 1 if !%$functions;

  while (my($key, $val) = each(%$functions)) {
    return 0 unless $val->{usage};
    return 0 unless $val->{signature};
    return 0 unless $val->{examples};
  }

  return 1;
}

method build_routines() {
  return if !$self->includes;

  $self->parse_routines;
  $self->check_routines or raise 'build routines failed';

  return $self->stash('routines');
}

method parse_routines() {
  my $source = $self->source->data;

  my $routines = {};

  for my $include (map { [split /\s*:\s*/]  } grep {length} @{$self->includes}) {
    next if $include->[0] ne 'routine';

    my $item = {};
    my $name = $include->[1];

    $item->{usage} = $source->contents('routine', $name);
    $item->{signature} = $source->contents('signature', $name);

    my $index = 1;
    while (my $content = $source->contents("example-$index", $name)) {
      last if !@$content;

      $item->{examples}{$index} = $content;
      $index++;
    }

    $routines->{$name} = $item;
  }

  return $self->stash(routines => $routines);
}

method check_routines() {
  my $routines = $self->stash('routines');

  return 1 if !%$routines;

  while (my($key, $val) = each(%$routines)) {
    return 0 unless $val->{usage};
    return 0 unless $val->{signature};
    return 0 unless $val->{examples};
  }

  return 1;
}

method scenarios($name, $attr) {
  my $scenarios = $self->stash('scenarios');

  return $scenarios if !$name;

  my $result = $scenarios->{$name};

  return $result if !$attr;

  return $result->{$attr};
}

method methods($name, $attr) {
  my $methods = $self->stash('methods');

  return $methods if !$name;

  my $result = $methods->{$name};

  return $result if !$attr;

  return $result->{$attr};
}

method functions($name, $attr) {
  my $functions = $self->stash('functions');

  return $functions if !$name;

  my $result = $functions->{$name};

  return $result if !$attr;

  return $result->{$attr};
}

method routines($name, $attr) {
  my $routines = $self->stash('routines');

  return $routines if !$name;

  my $result = $routines->{$name};

  return $result if !$attr;

  return $result->{$attr};
}

method render($method, @args) {
  my $newline = "\n";

  my $results = $self->$method(@args) or return "";

  return join $newline, @$results;
}

1;

=encoding utf8

=head1 NAME

Test::Auto::Parser

=cut

=head1 ABSTRACT

Specification Parser

=cut

=head1 SYNOPSIS

  package main;

  use Test::Auto;
  use Test::Auto::Parser;

  my $test = Test::Auto->new(
    't/Test_Auto_Parser.t'
  );

  my $parser = Test::Auto::Parser->new(
    source => $test
  );

=cut

=head1 DESCRIPTION

This package use the L<Test::Auto> object as a parser target, where the
object's file property points to a test file containing POD blocks which adhere
to the specification as defined in L<Test::Auto/SPECIFICATION>, parses the test
file and returns a parser object for accessing the data.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Data::Object::Library>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 abstract

  abstract(ArrayRef[Str])

This attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

=cut

=head2 attributes

  attributes(ArrayRef[Str])

This attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

=cut

=head2 description

  description(ArrayRef[Str])

This attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

=cut

=head2 footers

  footers(ArrayRef[Str])

This attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

=cut

=head2 headers

  headers(ArrayRef[Str])

This attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

=cut

=head2 includes

  includes(ArrayRef[Str])

This attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

=cut

=head2 inherits

  inherits(ArrayRef[Str])

This attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

=cut

=head2 integrates

  integrates(ArrayRef[Str])

This attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

=cut

=head2 libraries

  libraries(ArrayRef[Str])

This attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

=cut

=head2 name

  name(ArrayRef[Str])

This attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

=cut

=head2 source

  source(InstanceOf["Test::Auto"])

This attribute is read-only, accepts C<(InstanceOf["Test::Auto"])> values, and is required.

=cut

=head2 synopsis

  synopsis(ArrayRef[Str])

This attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

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
