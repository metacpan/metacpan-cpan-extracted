package Test::Auto::Parser;

use strict;
use warnings;

use Moo;
use Test::Auto::Types ();

require Carp;

our $VERSION = '0.12'; # VERSION

# ATTRIBUTES

has name => (
  is => 'ro',
  isa => Test::Auto::Types::Strings(),
  required => 0
);

has tagline => (
  is => 'ro',
  isa => Test::Auto::Types::Strings(),
  required => 0
);

has abstract => (
  is => 'ro',
  isa => Test::Auto::Types::Strings(),
  required => 0
);

has synopsis => (
  is => 'ro',
  isa => Test::Auto::Types::Strings(),
  required => 0
);

has includes => (
  is => 'ro',
  isa => Test::Auto::Types::Strings(),
  required => 0
);

has description => (
  is => 'ro',
  isa => Test::Auto::Types::Strings(),
  required => 0
);

has inherits => (
  is => 'ro',
  isa => Test::Auto::Types::Strings(),
  required => 0
);

has integrates => (
  is => 'ro',
  isa => Test::Auto::Types::Strings(),
  required => 0
);

has attributes => (
  is => 'ro',
  isa => Test::Auto::Types::Strings(),
  required => 0
);

has libraries => (
  is => 'ro',
  isa => Test::Auto::Types::Strings(),
  required => 0
);

has headers => (
  is => 'ro',
  isa => Test::Auto::Types::Strings(),
  required => 0
);

has footers => (
  is => 'ro',
  isa => Test::Auto::Types::Strings(),
  required => 0
);

has source => (
  is => 'ro',
  isa => Test::Auto::Types::Source(),
  required => 1
);

# BUILD

sub BUILD {
  my  ($self, $args) = @_;

  $self->{'$stash'} = {} if !$self->{'$stash'};

  my $source = $self->source->data;

  $self->build_name;
  $self->build_tagline;
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
  $self->build_types;

  return $self;
}

# METHODS

sub build_name {
  my ($self) = @_;

  $self->parse_name;
  $self->check_name or Carp::confess 'build name failed';

  return $self->name;
}

sub parse_name {
  my ($self) = @_;

  my $source = $self->source->data;

  return $self->{name} = $source->content('name');
}

sub check_name {
  my ($self) = @_;

  my $name = $self->name;

  return 1 if !$name;

  return 0 if $name->[0] =~ /[^\w\'\:']/;

  return 1;
}

sub build_tagline {
  my ($self) = @_;

  $self->parse_tagline;

  return $self->tagline;
}

sub parse_tagline {
  my ($self) = @_;

  my $source = $self->source->data;

  return $self->{tagline} = $source->content('tagline');
}

sub build_abstract {
  my ($self) = @_;

  $self->parse_abstract;
  $self->check_abstract or Carp::confess 'build abstract failed';

  return $self->abstract;
}

sub parse_abstract {
  my ($self) = @_;

  my $source = $self->source->data;

  return $self->{abstract} = $source->content('abstract');
}

sub check_abstract {
  my ($self) = @_;

  my $abstract = $self->abstract;

  return 1 if !$abstract;

  return 0 if $abstract->[0] !~ /\w/;

  return 1;
}

sub build_synopsis {
  my ($self) = @_;

  $self->parse_synopsis;
  $self->check_synopsis or Carp::confess 'build synopsis failed';

  return $self->synopsis;
}

sub parse_synopsis {
  my ($self) = @_;

  my $source = $self->source->data;

  return $self->{synopsis} = $source->content('synopsis');
}

sub check_synopsis {
  my ($self) = @_;

  my $synopsis = $self->synopsis;

  return 1 if !$synopsis;

  return 0 if $synopsis->[0] !~ /\w/;

  return 1;
}

sub build_includes {
  my ($self) = @_;

  $self->parse_includes;
  $self->check_includes or Carp::confess 'build includes failed';

  return $self->includes;
}

sub parse_includes {
  my ($self) = @_;

  my $source = $self->source->data;

  return $self->{includes} = $source->content('includes');
}

sub check_includes {
  my ($self) = @_;

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

sub build_description {
  my ($self) = @_;

  $self->parse_description;
  $self->check_description or Carp::confess 'build description failed';

  return $self->description;
}

sub parse_description {
  my ($self) = @_;

  my $source = $self->source->data;

  return $self->{description} = $source->content('description');
}

sub check_description {
  my ($self) = @_;

  my $description = $self->description;

  return 0 if !$description;
  return 1;
}

sub build_inherits {
  my ($self) = @_;

  $self->parse_inherits;
  $self->check_inherits or Carp::confess 'build inherits failed';

  return $self->inherits;
}

sub parse_inherits {
  my ($self) = @_;

  my $source = $self->source->data;

  return $self->{inherits} = $source->content('inherits');
}

sub check_inherits {
  my ($self) = @_;

  my $inherits = $self->inherits;

  return 1 if !$inherits;

  for my $inherit (@$inherits) {
    return 0 if $inherit =~ /[^\w\'\:']/;
  }

  return 1;
}

sub build_integrates {
  my ($self) = @_;

  $self->parse_integrates;
  $self->check_integrates or Carp::confess 'build integrates failed';

  return $self->integrates;
}

sub parse_integrates {
  my ($self) = @_;

  my $source = $self->source->data;

  return $self->{integrates} = $source->content('integrates');
}

sub check_integrates {
  my ($self) = @_;

  my $integrates = $self->integrates;

  return 1 if !$integrates;

  for my $integrate (@$integrates) {
    return 0 if $integrate =~ /[^\w\'\:']/;
  }

  return 1;
}

sub build_attributes {
  my ($self) = @_;

  $self->parse_attributes;
  $self->check_attributes or Carp::confess 'build attributes failed';

  return $self->attributes;
}

sub parse_attributes {
  my ($self) = @_;

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

sub check_attributes {
  my ($self) = @_;

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

sub build_libraries {
  my ($self) = @_;

  $self->parse_libraries;
  $self->check_libraries or Carp::confess 'build libraries failed';

  return $self->libraries;
}

sub parse_libraries {
  my ($self) = @_;

  my $source = $self->source->data;

  return $self->{libraries} = $source->content('libraries');
}

sub check_libraries {
  my ($self) = @_;

  my $libraries = $self->libraries;

  return 1 if !$libraries;

  for my $library (@$libraries) {
    return 0 if $library =~ /[^\w\'\:']/;
  }

  return 1;
}

sub build_headers {
  my ($self) = @_;

  $self->parse_headers;
  $self->check_headers or Carp::confess 'build headers failed';

  return $self->headers;
}

sub parse_headers {
  my ($self) = @_;

  my $source = $self->source->data;

  return $self->{headers} = $source->content('headers');
}

sub check_headers {
  my ($self) = @_;

  my $headers = $self->headers;

  return 1 if !$headers;

  return 0 unless scalar @$headers;

  return 1;
}

sub build_footers {
  my ($self) = @_;

  $self->parse_footers;
  $self->check_footers or Carp::confess 'build footers failed';

  return $self->footers;
}

sub parse_footers {
  my ($self) = @_;

  my $source = $self->source->data;

  return $self->{footers} = $source->content('footers');
}

sub check_footers {
  my ($self) = @_;

  my $footers = $self->footers;

  return 1 if !$footers;

  return 0 unless scalar @$footers;

  return 1;
}

sub build_scenarios {
  my ($self) = @_;

  $self->parse_scenarios;
  $self->check_scenarios or Carp::confess 'build scenarios failed';

  return $self->stash('scenarios');
}

sub parse_scenarios {
  my ($self) = @_;

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

sub check_scenarios {
  my ($self) = @_;

  my $scenarios = $self->stash('scenarios');

  return 1 if !%$scenarios;

  while (my($key, $val) = each(%$scenarios)) {
    return 0 unless $val->{usage};
    return 0 unless $val->{example};
  }

  return 1;
}

sub build_methods {
  my ($self) = @_;

  return if !$self->includes;

  $self->parse_methods;
  $self->check_methods or Carp::confess 'build methods failed';

  return $self->stash('methods');
}

sub parse_methods {
  my ($self) = @_;

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

sub check_methods {
  my ($self) = @_;

  my $methods = $self->stash('methods');

  return 1 if !%$methods;

  while (my($key, $val) = each(%$methods)) {
    unless ($val->{usage} && @{$val->{usage}}) {
      warn "Missing: $key (usage)";
      return 0;
    }
    unless ($val->{signature} && @{$val->{signature}}) {
      warn "Missing: $key (signature)";
      return 0;
    }
    unless ($val->{examples}) {
      warn "Missing: $key (examples)";
      return 0;
    }
  }

  return 1;
}

sub build_functions {
  my ($self) = @_;

  return if !$self->includes;

  $self->parse_functions;
  $self->check_functions or Carp::confess 'build functions failed';

  return $self->stash('functions');
}

sub parse_functions {
  my ($self) = @_;

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

sub check_functions {
  my ($self) = @_;

  my $functions = $self->stash('functions');

  return 1 if !%$functions;

  while (my($key, $val) = each(%$functions)) {
    unless ($val->{usage} && @{$val->{usage}}) {
      warn "Missing: $key (usage)";
      return 0;
    }
    unless ($val->{signature} && @{$val->{signature}}) {
      warn "Missing: $key (signature)";
      return 0;
    }
    unless ($val->{examples}) {
      warn "Missing: $key (examples)";
      return 0;
    }
  }

  return 1;
}

sub build_routines {
  my ($self) = @_;

  return if !$self->includes;

  $self->parse_routines;
  $self->check_routines or Carp::confess 'build routines failed';

  return $self->stash('routines');
}

sub parse_routines {
  my ($self) = @_;

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

sub check_routines {
  my ($self) = @_;

  my $routines = $self->stash('routines');

  return 1 if !%$routines;

  while (my($key, $val) = each(%$routines)) {
    unless ($val->{usage} && @{$val->{usage}}) {
      warn "Missing: $key (usage)";
      return 0;
    }
    unless ($val->{signature} && @{$val->{signature}}) {
      warn "Missing: $key (signature)";
      return 0;
    }
    unless ($val->{examples}) {
      warn "Missing: $key (examples)";
      return 0;
    }
  }

  return 1;
}

sub build_types {
  my ($self) = @_;

  $self->parse_types;
  $self->check_types or Carp::confess 'build types failed';

  return $self->stash('types');
}

sub parse_types {
  my ($self) = @_;

  my $source = $self->source->data;

  my $types = {};
  my $listings = $source->list('type');

  for my $name (map {$$_{name}} @{$listings}) {
    my $item = {};

    $item->{usage} = $source->contents('type', $name);
    $item->{library} = $source->contents('type-library', $name);
    $item->{parent} = $source->contents('type-parent', $name);
    $item->{composite} = $source->contents('type-composite', $name);

    my $index;

    $index = 1;
    while (my $content = $source->contents("type-coercion-$index", $name)) {
      last if !@$content;

      $item->{coercions}{$index} = $content;
      $index++;
    }

    $index = 1;
    while (my $content = $source->contents("type-example-$index", $name)) {
      last if !@$content;

      $item->{examples}{$index} = $content;
      $index++;
    }

    $types->{$name} = $item;
  }

  return $self->stash(types => $types);
}

sub check_types {
  my ($self) = @_;

  my $types = $self->stash('types');

  return 1 if !%$types;

  while (my($key, $val) = each(%$types)) {
    return 0 unless $val->{usage};
    return 0 unless $val->{library};
    return 0 unless $val->{examples};
  }

  return 1;
}

sub scenarios {
  my ($self, $name, $attr) = @_;

  my $scenarios = $self->stash('scenarios');

  return $scenarios if !$name;

  my $result = $scenarios->{$name};

  return $result if !$attr;

  return $result->{$attr};
}

sub methods {
  my ($self, $name, $attr) = @_;

  my $methods = $self->stash('methods');

  return $methods if !$name;

  my $result = $methods->{$name};

  return $result if !$attr;

  return $result->{$attr};
}

sub functions {
  my ($self, $name, $attr) = @_;

  my $functions = $self->stash('functions');

  return $functions if !$name;

  my $result = $functions->{$name};

  return $result if !$attr;

  return $result->{$attr};
}

sub routines {
  my ($self, $name, $attr) = @_;

  my $routines = $self->stash('routines');

  return $routines if !$name;

  my $result = $routines->{$name};

  return $result if !$attr;

  return $result->{$attr};
}

sub types {
  my ($self, $name, $attr) = @_;

  my $types = $self->stash('types');

  return $types if !$name;

  my $result = $types->{$name};

  return $result if !$attr;

  return $result->{$attr};
}

sub render {
  my ($self, $method, @args) = @_;

  my $newline = "\n";

  my $results = $self->$method(@args) or return "";

  return join $newline, @$results;
}

sub stash {
  my ($self, $key, $value) = @_;

  return $self->{'$stash'} if !exists $_[1];

  return $self->{'$stash'}->{$key} if !exists $_[2];

  $self->{'$stash'}->{$key} = $value;

  return $value;
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

This package parses files containing POD blocks which adhere to the
specification as defined in L<Test::Auto/SPECIFICATION>, and provides methods
for accessing the data.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Test::Auto::Types>

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

  source(Source)

This attribute is read-only, accepts C<(Source)> values, and is required.

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

L<Wiki|https://github.com/iamalnewkirk/test-auto/wiki>

L<Project|https://github.com/iamalnewkirk/test-auto>

L<Initiatives|https://github.com/iamalnewkirk/test-auto/projects>

L<Milestones|https://github.com/iamalnewkirk/test-auto/milestones>

L<Issues|https://github.com/iamalnewkirk/test-auto/issues>

=cut
