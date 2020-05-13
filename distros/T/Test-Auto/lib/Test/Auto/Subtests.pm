package Test::Auto::Subtests;

use strict;
use warnings;

use feature 'state';

use Moo;
use Test::Auto::Try;
use Test::Auto::Types ();
use Test::More;
use Type::Registry;

require Carp;

our $VERSION = '0.12'; # VERSION

# ATTRIBUTES

has parser => (
  is => 'ro',
  isa => Test::Auto::Types::Parser(),
  required => 1
);

# METHODS

sub standard {
  my ($self) = @_;

  $self->package;
  $self->document;
  $self->libraries;
  $self->inherits;
  $self->attributes;
  $self->methods;
  $self->routines;
  $self->functions;
  $self->types;

  return $self;
}

sub package {
  my ($self) = @_;

  my $parser = $self->parser;

  subtest "testing package", sub {
    my $package = $parser->render('name')
      or plan skip_all => "no package";

    require_ok $package; # use_ok can't test roles
  };
}

sub plugin {
  my ($self, $name) = @_;

  my $package = join '::', map ucfirst, (
    'test', 'auto', 'plugin', $name
  );

  subtest "testing plugin ($name)", sub {
    use_ok $package
      or plan skip_all => "$package not loaded";

    ok $package->isa('Test::Auto::Plugin'), 'isa Test::Auto::Plugin';
  };

  my $instance = $package->new(subtests => $self);

  return $instance;
}

sub libraries {
  my ($self) = @_;

  my $parser = $self->parser;

  subtest "testing libraries", sub {
    my $packages = $parser->libraries
      or plan skip_all => "no libraries";

    map +(use_ok $_), @$packages;
  };
}

sub inherits {
  my ($self) = @_;

  my $parser = $self->parser;

  subtest "testing inherited", sub {
    my $inherited = $parser->inherits
      or plan skip_all => "no inherited";

    map +(use_ok $_), @$inherited;
  };
}

sub document {
  my ($self) = @_;

  my $parser = $self->parser;

  subtest "testing document", sub {
    ok $parser->render($_), "pod $_" for qw(
      name
      abstract
      synopsis
      abstract
      description
    );
  };
}

sub attributes {
  my ($self) = @_;

  my $parser = $self->parser;

  subtest "testing attributes", sub {
    my $package = $parser->render('name')
      or plan skip_all => "no package";

    my $attributes = $parser->stash('attributes');
    plan skip_all => 'no attributes' if !$attributes || !%$attributes;

    for my $name (sort keys %$attributes) {
      subtest "testing attribute $name", sub {
        my $attribute = $attributes->{$name};

        ok $package->can($name), 'can ok';
        ok $attribute->{is}, 'has $is';
        ok $attribute->{presence}, 'has $presence';
        ok $attribute->{type}, 'has $type';

        my $registry = $self->registry;
        ok !!$registry->lookup($attribute->{type}), 'valid $type';
      };
    }
  };
}

sub methods {
  my ($self) = @_;

  my $parser = $self->parser;

  subtest "testing methods", sub {
    my $package = $parser->render('name')
      or plan skip_all => "no package";

    my $methods = $parser->methods;
    plan skip_all => 'no methods' if !$methods || !%$methods;

    for my $name (sort keys %$methods) {
      subtest "testing method $name", sub {
        my $method = $methods->{$name};

        ok $package->can($name), 'can ok';
        ok $method->{usage}, 'pod description';
        ok $method->{signature}, 'pod signature';
        ok $method->{examples}{1}, 'pod example-1';
      };
    }
  };
}

sub routines {
  my ($self) = @_;

  my $parser = $self->parser;

  subtest "testing routines", sub {
    my $package = $parser->render('name')
      or plan skip_all => "no package";

    my $routines = $parser->routines;
    plan skip_all => 'no routines' if !$routines || !%$routines;

    for my $name (sort keys %$routines) {
      subtest "testing routine $name", sub {
        my $routine = $routines->{$name};

        ok $package->can($name), 'can ok';
        ok $routine->{usage}, 'pod description';
        ok $routine->{signature}, 'pod signature';
        ok $routine->{examples}{1}, 'pod example-1';
      };
    }
  };
}

sub functions {
  my ($self) = @_;

  my $parser = $self->parser;

  subtest "testing functions", sub {
    my $package = $parser->render('name')
      or plan skip_all => "no package";

    my $functions = $parser->functions;
    plan skip_all => 'no functions' if !$functions || !%$functions;

    for my $name (sort keys %$functions) {
      subtest "testing function $name", sub {
        my $function = $functions->{$name};

        ok $package->can($name), 'can ok';
        ok $function->{usage}, 'pod description';
        ok $function->{signature}, 'pod signature';
        ok $function->{examples}{1}, 'pod example-1';
      };
    }
  };
}

sub types {
  my ($self) = @_;

  my $parser = $self->parser;

  subtest "testing types", sub {
    my $types = $parser->types;
    plan skip_all => 'no types' if !$types || !%$types;

    for my $name (sort keys %$types) {
      subtest "testing type $name", sub {
        my $type = $types->{$name};

        my $library = $type->{library}[0][0]
          or plan skip_all => "no library";

        use_ok $library;
        ok $library->isa('Type::Library'), 'isa Type::Library';

        my $constraint = $library->get_type($name);
        ok $constraint, 'has constraint';

        if ($constraint) {
          ok $constraint->isa('Type::Tiny'), 'isa Type::Tiny constraint';

          for my $number (sort keys %{$type->{examples}}) {
            my $example = $type->{examples}{$number};
            my $context = join "\n", @{$example->[0]};

            subtest "testing example-$number ($name)", sub {
              my $tryable = $self->tryable($context)->call('evaluator');
              my $result = $tryable->result;

              ok $constraint->check($result), 'passed constraint check';
            };
          }

          for my $number (sort keys %{$type->{coercions}}) {
            my $coercion = $type->{coercions}{$number};
            my $context = join "\n", @{$coercion->[0]};

            subtest "testing coercion-$number ($name)", sub {
              my $tryable = $self->tryable($context)->call('evaluator');
              my $result = $tryable->result;

              ok $constraint->check($constraint->coerce($result)),
                'passed constraint coercion';
            };
          }
        }
      };
    }
  };
}

sub synopsis {
  my ($self, $callback) = @_;

  my $parser = $self->parser;

  my $context = $parser->render('synopsis');
  my $tryable = $self->tryable($context);

  subtest "testing synopsis", sub {
    my @results = $callback->($tryable->call('evaluator'));

    ok scalar(@results), 'called ok';
  };
}

sub scenario {
  my ($self, $name, $callback) = @_;

  my $parser = $self->parser;

  my @results;

  my $example = $parser->scenarios($name, 'example');
  my @content = $example ? @{$example->[0]} : ();

  unshift @content,
    (map $parser->render(split /\s/),
      (map +(/# given:\s*([\w\s-]+)/g), @content));

  my $tryable = $self->tryable(join "\n", @content);

  subtest "testing scenario ($name)", sub {
    unless (@content) {
      BAIL_OUT "unknown scenario $name";

      return;
    }
    @results = $callback->($tryable->call('evaluator'));

    ok scalar(@results), 'called ok';
  };
}

sub example {
  my ($self, $number, $name, $type, $callback) = @_;

  my $parser = $self->parser;

  my $context;
  my $signature;
  my @results;

  if ($type eq 'method') {
    $context = $parser->methods($name, 'examples');
    $signature = $parser->methods($name, 'signature');
    $signature = join "\n", @{$signature->[0]} if $signature;
  }
  elsif ($type eq 'function') {
    $context = $parser->functions($name, 'examples');
    $signature = $parser->functions($name, 'signature');
    $signature = join "\n", @{$signature->[0]} if $signature;
  }
  elsif ($type eq 'routine') {
    $context = $parser->routines($name, 'examples');
    $signature = $parser->routines($name, 'signature');
    $signature = join "\n", @{$signature->[0]} if $signature;
  }
  else {
    Carp::confess "$type is not a valid example type";
  }

  $number = abs $number;

  my $example = $context->{$number}[0] || [];
  my @content = @$example;

  unshift @content,
    (map $parser->render($_),
      (map +(/# given:\s*(\w+)/g), @content));

  my $tryable = $self->tryable(join "\n", @content);

  subtest "testing example-$number ($name)", sub {
    unless (@content) {
      BAIL_OUT "unknown $type $name for example-$number";

      return;
    }
    @results = $callback->($tryable->call('evaluator'));

    ok scalar(@results), 'called ok';
  };

  subtest "testing example-$number ($name) results", sub {
    unless (@content) {
      BAIL_OUT "unknown $type $name for example-$number";

      return;
    }
    my ($input, $output) = $signature =~ /(.*) : (.*)/;

    my $registry = $self->registry;

    ok my $type = $registry->lookup($output), 'return type ok';

    map +(ok $type ? $type->check($_) : (), 'return value(s) ok'), @results;
  };
}

sub evaluator {
  my ($self, $context) = @_;

  local $@;

  my $returned = eval "no warnings 'redefine';\n\n$context";
  my $failures = $@;

  if ($failures) {
    Carp::confess $failures
  }

  return $returned;
}

sub tryable {
  my ($self, @passed) = @_;

  my @arguments = (invocant => $self);

  push @arguments, arguments => [@passed] if @passed;

  return Test::Auto::Try->new(@arguments);
}

sub registry {
  my ($self) = @_;

  my $parser = $self->parser;
  my $libraries = $parser->libraries;
  my $package = $parser->name;

  $libraries = ['Types::Standard'] if !$libraries || !@$libraries;

  state $populate = 0;
  state $registry = Type::Registry->for_class($package);

  map $registry->add_types($_), @$libraries if !$populate++;

  return $registry;
}

1;

=encoding utf8

=head1 NAME

Test::Auto::Subtests

=cut

=head1 ABSTRACT

Testing Automation

=cut

=head1 SYNOPSIS

  package main;

  use Test::Auto;
  use Test::Auto::Parser;
  use Test::Auto::Subtests;

  my $test = Test::Auto->new(
    't/Test_Auto_Subtests.t'
  );

  my $parser = Test::Auto::Parser->new(
    source => $test
  );

  my $subtests = Test::Auto::Subtests->new(
    parser => $parser
  );

  # execute dynamic subtests

  # $subtests->standard

=cut

=head1 DESCRIPTION

This package use the L<Test::Auto::Parser> object to execute a set of dynamic
subtests.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Test::Auto::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 parser

  parser(Parser)

This attribute is read-only, accepts C<(Parser)> values, and is required.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 attributes

  attributes() : Any

This method registers and executes a subtest which tests the declared
attributes.

=over 4

=item attributes example #1

  # given: synopsis

  $subtests->attributes;

=back

=cut

=head2 document

  document() : Any

This method registers and executes a subtest which tests the test document
structure.

=over 4

=item document example #1

  # given: synopsis

  $subtests->document;

=back

=cut

=head2 evaluator

  evaluator(Str $context) : Any

This method evaluates (using C<eval>) the context given and returns the result
or raises an exception.

=over 4

=item evaluator example #1

  # given: synopsis

  my $context = '1 + 1';

  $subtests->evaluator($context); # 2

=back

=cut

=head2 example

  example(Num $number, Str $name, Str $type, CodeRef $callback) : Any

This method finds and evaluates (using C<eval>) the documented example and
returns a C<Test::Auto::Try> object (see L<Data::Object::Try>). The C<try>
object can be used to trap exceptions using the C<catch> method, and/or execute
the code and return the result using the C<result> method.

=over 4

=item example example #1

  # given: synopsis

  $subtests->example(1, 'evaluator', 'method', sub {
    my ($tryable) = @_;

    ok my $result = $tryable->result, 'result ok';
    is $result, 2, 'meta evaluator test ok';

    $result;
  });

=back

=cut

=head2 functions

  functions() : Any

This method registers and executes a subtest which tests the declared
functions.

=over 4

=item functions example #1

  # given: synopsis

  $subtests->functions;

=back

=cut

=head2 inherits

  inherits() : Any

This method registers and executes a subtest which tests the declared
inheritances.

=over 4

=item inherits example #1

  # given: synopsis

  $subtests->inherits;

=back

=cut

=head2 libraries

  libraries() : Any

This method registers and executes a subtest which tests the declared
type libraries.

=over 4

=item libraries example #1

  # given: synopsis

  $subtests->libraries;

=back

=cut

=head2 methods

  methods() : Any

This method registers and executes a subtest which tests the declared
methods.

=over 4

=item methods example #1

  # given: synopsis

  $subtests->methods;

=back

=cut

=head2 package

  package() : Any

This method registers and executes a subtest which tests the declared
package.

=over 4

=item package example #1

  # given: synopsis

  $subtests->package;

=back

=cut

=head2 plugin

  plugin(Str $name) : Object

This method builds, tests, and returns a plugin object based on the name
provided.

=over 4

=item plugin example #1

  # given: synopsis

  $subtests->plugin('ShortDescription');

=back

=cut

=head2 registry

  registry() : InstanceOf["Type::Registry"]

This method returns a type registry object comprised of the types declare in
the declared type libraries.

=over 4

=item registry example #1

  # given: synopsis

  my $registry = $subtests->registry;

=back

=cut

=head2 routines

  routines() : Any

This method registers and executes a subtest which tests the declared
routines.

=over 4

=item routines example #1

  # given: synopsis

  $subtests->routines;

=back

=cut

=head2 scenario

  scenario(Str $name, CodeRef $callback) : Any

This method finds and evaluates (using C<eval>) the documented scenario example
and returns a C<Test::Auto::Try> object (see L<Data::Object::Try>). The C<try>
object can be used to trap exceptions using the C<catch> method, and/or execute
the code and return the result using the C<result> method.

=over 4

=item scenario example #1

  package main;

  use Test::Auto;

  my $test = Test::Auto->new(
    't/Test_Auto.t'
  );

  my $subtests = $test->subtests;

  $subtests->scenario('exports', sub {
    my ($tryable) = @_;

    ok my $result = $tryable->result, 'result ok';

    $result;
  });

=back

=cut

=head2 standard

  standard() : Subtests

This method is shorthand which registers and executes a series of other
standard subtests.

=over 4

=item standard example #1

  # given: synopsis

  # use:
  $subtests->standard;

  # instead of:
  # $self->package;
  # $self->document;
  # $self->libraries;
  # $self->inherits;
  # $self->attributes;
  # $self->methods;
  # $self->routines;
  # $self->functions;
  # $self->types;

=back

=cut

=head2 synopsis

  synopsis(CodeRef $callback) : Any

This method evaluates (using C<eval>) the documented synopsis and returns a
C<Test::Auto::Try> object (see L<Data::Object::Try>). The C<try> object can be
used to trap exceptions using the C<catch> method, and/or execute the code and
return the result using the C<result> method.

=over 4

=item synopsis example #1

  # given: synopsis

  $subtests->synopsis(sub {
    my ($tryable) = @_;

    ok my $result = $tryable->result, 'result ok';
    is ref($result), 'Test::Auto::Subtests', 'isa ok';

    $result;
  });

=back

=cut

=head2 tryable

  tryable(Any @arguments) : InstanceOf["Test::Auto::Try"]

This method returns a tryable object which can be used to defer code execution
with a try/catch construct.

=over 4

=item tryable example #1

  # given: synopsis

  my $tryable = $subtests->tryable;

  $tryable->call(sub { $_[0] + 1 });

  # $tryable->result(1);
  #> 2

=back

=over 4

=item tryable example #2

  # given: synopsis

  my $tryable = $subtests->tryable(1);

  $tryable->call(sub { $_[0] + $_[1] });

  # $tryable->result(1);
  #> 2

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
