package Rewire;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;
use Data::Object::Space;

use Carp;
use JSON::Validator;
use Rewire::Engine;

with 'Data::Object::Role::Buildable';
with 'Data::Object::Role::Proxyable';

our $VERSION = '0.06'; # VERSION

# BUILD

fun build_self($self, $args) {

  # build context and eager load services
  return $self->context;
}

fun build_proxy($self, $package, $method, @args) {
  return unless $self->config->{services}{$method};

  return sub {

    return $self->process($method, @args);
  }
}

# ATTRIBUTES

has 'context' => (
  is => 'ro',
  isa => 'CodeRef',
  new => 1
);

fun new_context($self) {
  $self->engine->call('preload', $self->config);
}

has 'engine' => (
  is => 'ro',
  isa => 'InstanceOf["Data::Object::Space"]',
  new => 1
);

fun new_engine($self) {
  Data::Object::Space->new('Rewire::Engine');
}

has 'metadata' => (
  is => 'ro',
  isa => 'HashRef',
  opt => 1
);

has 'services' => (
  is => 'ro',
  isa => 'HashRef',
  opt => 1
);

# METHODS

method config() {
  {
    metadata => $self->metadata || {},
    services => $self->services || {},
  }
}

method resolve(Str $name) {
  my $engine = $self->engine;

  my $result = $engine->call('reifier', $name, $self->config, $self->context);

  return $result;
}

method process(Str $name, Any $argument, Maybe[Str] $argument_as) {
  my $engine = $self->engine;
  my $service = $self->services->{$name} or return;

  my $generated = {
    %$service, $argument_as ? (argument_as => $argument_as) : ()
  };

 $argument //= $service->{argument};

  my $params = $engine->call('resolver', $argument, $self->config, $self->context);
  my $result = $engine->call( 'builder', $generated, $params // $service->{argument});

  return $result;
}

method validate() {
  my $engine = $self->engine;

  my $json = JSON::Validator->new;

  $json->schema($engine->call('ruleset'));

  my @errors = map "$_", $json->validate($self->config);

  confess join "\n", @errors if @errors;

  return $self;
}

1;

=encoding utf8

=head1 NAME

Rewire - Dependency Injection

=cut

=head1 ABSTRACT

Dependency Injection Container for Perl 5

=cut

=head1 SYNOPSIS

  use Rewire;

  my $services = {
    filetemp => {
      package => 'File/Temp'
    },
    tempfile => {
      package => 'Mojo/File',
      argument => { '$service' => 'filetemp' }
    }
  };

  my $rewire = Rewire->new(services => $services);

  $rewire->resolve('tempfile');

=cut

=head1 DESCRIPTION

This package provides methods for using dependency injection, and building
objects and values.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Data::Object::Role::Buildable>

L<Data::Object::Role::Proxyable>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 SCENARIOS

This package supports the following scenarios:

=cut

=head2 $callback

  use Rewire;

  my $services = {
    io => {
      package => 'IO/Handle'
    },
    log => {
      package => 'Mojo/Log',
      argument => {
        format => { '$callback' => 'io' }
      }
    },
  };

  my $rewire = Rewire->new(
    services => $services
  );

This package supports resolving services as callbacks to be passed around
and/or resolved by other services. The C<$callback> directive is used to
specify the name of a service to be resolved and passed as an argument.

=cut

=head2 $envvar

  use Rewire;

  my $services = {
    file => {
      package => 'Mojo/File',
      argument => { '$envvar' => 'home' }
    }
  };

  my $rewire = Rewire->new(
    services => $services
  );

This package supports inlining environment variables as arguments to services.
The C<$envvar> directive is used to specify the name of an environment
variable, and can also be used in metadata for reusability.

=cut

=head2 $function

  use Rewire;

  my $services = {
    temp => {
      package => 'File/Temp'
    },
    file => {
      package => 'Mojo/File',
      argument => { '$function' => 'temp#tempfile' }
    }
  };

  my $rewire = Rewire->new(
    services => $services
  );

This package supports inlining the result of a service resolution and function
call as arguments to services. The C<#> delimited C<$function> directive is
used to specify the name of an existing service on the right-hand side, and an
arbitrary function to be call on the result on the left-hand side.

=cut

=head2 $metadata

  use Rewire;

  my $metadata = {
    home => '/home/ubuntu'
  };

  my $services = {
    file => {
      package => 'Mojo/File',
      argument => { '$metadata' => 'home' }
    }
  };

  my $rewire = Rewire->new(
    metadata => $metadata,
    services => $services
  );

This package supports inlining configuration data as arguments to services.
The C<$metadata> directive is used to specify the name of a stashed
configuration value or data structure.

=cut

=head2 $method

  use Rewire;

  my $services = {
    temp => {
      package => 'File/Temp'
    },
    file => {
      package => 'Mojo/File',
      argument => { '$method' => 'temp#filename' }
    }
  };

  my $rewire = Rewire->new(
    services => $services
  );

This package supports inlining the result of a service resolution and method
call as arguments to services. The C<#> delimited C<$method> directive is used
to specify the name of an existing service on the right-hand side, and an
arbitrary method to be call on the result on the left-hand side.

=cut

=head2 $routine

  use Rewire;

  my $services = {
    temp => {
      package => 'File/Temp'
    },
    file => {
      package => 'Mojo/File',
      argument => { '$routine' => 'temp#tempfile' }
    }
  };

  my $rewire = Rewire->new(
    services => $services
  );

This package supports inlining the result of a service resolution and routine
call as arguments to services. The C<#> delimited C<$routine> directive is
used to specify the name of an existing service on the right-hand side, and an
arbitrary routine to be call on the result on the left-hand side.

=cut

=head2 $service

  use Rewire;

  my $services = {
    io => {
      package => 'IO/Handle'
    },
    log => {
      package => 'Mojo/Log',
      argument => {
        handle => { '$service' => 'io' }
      }
    },
  };

  my $rewire = Rewire->new(
    services => $services
  );

This package supports inlining resolved services as arguments to other
services. The C<$service> directive is used to specify the name of a service
to be resolved and passed as an argument.

=cut

=head2 arguments

  use Rewire;

  my $metadata = {
    applog => '/var/log/rewire.log'
  };

  my $services = {
    mojo_log => {
      package => 'Mojo/Log',
      argument => {
        path => { '$metadata' => 'applog' },
        level => 'warn'
      },
      argument_as => 'list'
    }
  };

  my $rewire = Rewire->new(
    services => $services,
    metadata => $metadata
  );

This package supports providing static and/or dynamic arguments during object
construction from C<metadata> or other C<services>.

=cut

=head2 builder

  use Rewire;

  my $services = {
    mojo_date => {
      package => 'Mojo/Date',
      builder => [
        {
          method => 'new',
          return => 'self'
        },
        {
          method => 'to_datetime',
          return => 'result'
        }
      ]
    }
  };

  my $rewire = Rewire->new(
    services => $services,
  );

This package supports specifying multiple build steps as C<function>,
C<method>, and C<routine> calls and chaining them together.

=cut

=head2 config

  use Rewire;

  my $metadata = {
    home => '/home/ubuntu'
  };

  my $services = {
    tempfile => {
      package => 'Mojo/File',
      argument => { '$metadata' => 'home' }
    }
  };

  my $rewire = Rewire->new(
    services => $services,
    metadata => $metadata
  );

This package supports configuring services and metadata in the service of
building objects and values.

=cut

=head2 constructor

  use Rewire;

  my $services = {
    mojo_date => {
      package => 'Mojo/Date',
      constructor => 'new'
    }
  };

  my $rewire = Rewire->new(
    services => $services
  );

This package supports specifying constructors other than the traditional C<new>
routine. A constructor is always called with the package name as the invocant.

=cut

=head2 extends

  use Rewire;

  my $services = {
    io => {
      package => 'IO/Handle'
    },
    log => {
      package => 'Mojo/Log',
      argument => {
        handle => { '$service' => 'io' }
      }
    },
    development_log => {
      package => 'Mojo/Log',
      extends => 'log',
      builder => [
        {
          method => 'new',
          return => 'self'
        },
        {
          method => 'path',
          argument => '/tmp/development.log',
          return => 'none'
        },
        {
          method => 'level',
          argument => 'debug',
          return => 'none'
        }
      ]
    },
    production_log => {
      package => 'Mojo/Log',
      extends => 'log',
      builder => [
        {
          method => 'new',
          return => 'self'
        },
        {
          method => 'path',
          argument => '/tmp/production.log',
          return => 'none'
        },
        {
          method => 'level',
          argument => 'warn',
          return => 'none'
        }
      ]
    },
    staging_log => {
      package => 'Mojo/Log',
      extends => 'development_log',
    },
    testing_log => {
      package => 'Mojo/Log',
      extends => 'log',
    },
  };

  my $rewire = Rewire->new(
    services => $services
  );

This package supports extending services in the definition of other services,
recursively compiling service configurations and eventually executing the
requested compiled service.

=cut

=head2 function

  use Rewire;

  my $services = {
    foo_sum => {
      package => 'Mojo/Util',
      function => 'md5_sum',
      argument => 'foo',
    }
  };

  my $rewire = Rewire->new(
    services => $services,
  );

This package supports specifying construction as a function call, which when
called does not provide an invocant.

=cut

=head2 lifecycle

  use Rewire;

  my $metadata = {
    home => '/home/ubuntu'
  };

  my $services = {
    tempfile => {
      package => 'Mojo/File',
      argument => { '$metadata' => 'home' },
      lifecycle => 'singleton'
    }
  };

  my $rewire = Rewire->new(
    services => $services,
    metadata => $metadata
  );

This package supports different lifecycle options which determine when services
are built and whether they're persisted.

=cut

=head2 metadata

  use Rewire;

  my $metadata = {
    homedir => '/home',
    tempdir => '/tmp'
  };

  my $services = {
    home => {
      package => 'Mojo/Path',
      argument => { '$metadata' => 'homedir' },
    },
    temp => {
      package => 'Mojo/Path',
      argument => { '$metadata' => 'tempdir' },
    }
  };

  my $rewire = Rewire->new(
    services => $services,
    metadata => $metadata
  );

This package supports specifying data and structures which can be used in the
construction of multiple services.

=cut

=head2 method

  use Rewire;

  my $services = {
    mojo_url => {
      package => 'Mojo/URL',
      argument => 'https://perl.org',
      method => 'new'
    }
  };

  my $rewire = Rewire->new(
    services => $services,
  );

This package supports specifying construction as a method call, which when
called provides the package or object instance as the invocant.

=cut

=head2 proxyable

  use Rewire;

  my $services = {
    home => {
      package => 'Mojo/Path',
      argument => '/home',
    },
    temp => {
      package => 'Mojo/Path',
      argument => '/tmp',
    }
  };

  my $rewire = Rewire->new(
    services => $services
  );

  # resolve services via method calls
  [
    $rewire->home, # i.e. $rewire->process('home')
    $rewire->temp  # i.e. $rewire->process('temp')
  ]

This package supports the resolution of services using a single method call.
This is enabled by intercepting method calls and proxying them to the
L</process> method.

=cut

=head2 routine

  use Rewire;

  my $services = {
    mojo_url => {
      package => 'Mojo/URL',
      argument => 'https://perl.org',
      routine => 'new'
    }
  };

  my $rewire = Rewire->new(
    services => $services,
  );

This package supports specifying construction as a function call, which when
called provides the package as the invocant.

=cut

=head2 service

  my $metadata = {
    home => '/home/ubuntu'
  };

  my $services = {
    tempfile => {
      package => 'Mojo/File',
      argument => { '$metadata' => 'home' },
      lifecycle => 'eager'
    }
  };

  my $rewire = Rewire->new(
    services => $services,
    metadata => $metadata
  );

This package supports defining services to be constructed on-demand or
automatically on instantiation.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 context

  context(CodeRef)

This attribute is read-only, accepts C<(CodeRef)> values, and is optional.

=cut

=head2 engine

  engine(InstanceOf["Data::Object::Space"])

This attribute is read-only, accepts C<(InstanceOf["Data::Object::Space"])> values, and is optional.

=cut

=head2 metadata

  metadata(HashRef)

This attribute is read-only, accepts C<(HashRef)> values, and is optional.

=cut

=head2 services

  services(HashRef)

This attribute is read-only, accepts C<(HashRef)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 config

  config() : HashRef

The config method returns the configuration based on the C<services> and
C<metadata> attributes.

=over 4

=item config example #1

  # given: synopsis

  $rewire->config;

=back

=cut

=head2 process

  process(Str $name, Any $argument, Maybe[Str] $argument_as) : Any

The process method processes and returns an object or value based on the
service named but where the arguments are provided ad-hoc. B<Note:> This method
is meant to be used to construct services ad-hoc and as such bypasses caching
and lifecycle effects.

=over 4

=item process example #1

  # given: synopsis

  $rewire->process('tempfile', 'rewire.tmp');

=back

=over 4

=item process example #2

  use Rewire;

  my $metadata = {
    logfile => '/var/log/rewire.log',
  };

  my $services = {
    mojo_log => {
      package => 'Mojo/Log',
      argument => { '$metadata' => 'logfile' },
    }
  };

  my $rewire = Rewire->new(
    services => $services,
    metadata => $metadata
  );

  $rewire->process('mojo_log', {
    level => 'fatal',
    path => { '$metadata' => 'logfile' }
  });

=back

=over 4

=item process example #3

  use Rewire;

  my $metadata = {
    logfile => '/var/log/rewire.log',
  };

  my $services = {
    mojo_log => {
      package => 'Mojo/Log',
      builder => [
        {
          method => 'new',
          return => 'self'
        }
      ]
    }
  };

  my $rewire = Rewire->new(
    services => $services,
    metadata => $metadata
  );

  $rewire->process('mojo_log', {
    level => 'fatal',
    path => { '$metadata' => 'logfile' }
  });

=back

=cut

=head2 resolve

  resolve(Str $name) : Any

The resolve method resolves and returns an object or value based on the service
named. B<Note:> This method is recommended to be used to construct services as
defined by the configuration and as such doesn't not allow passing additional
arguments.

=over 4

=item resolve example #1

  # given: synopsis

  $rewire->resolve('tempfile');

=back

=over 4

=item resolve example #2

  use Rewire;

  my $services = {
    mojo_log => {
      package => 'Mojo/Log',
      argument => {
        level => 'fatal',
        path => '/var/log/rewire.log'
      },
    }
  };

  my $rewire = Rewire->new(
    services => $services,
  );

  $rewire->resolve('mojo_log');

=back

=over 4

=item resolve example #3

  package Dynamic;

  sub import;

  sub AUTOLOAD {
    bless {};
  }

  sub DESTROY {
    ; # noop
  }

  package main;

  use Rewire;

  my $services = {
    dynamic => {
      package => 'Dynamic',
      builder => [
        {
          method => 'new',
          return => 'self'
        },
        {
          method => 'missing_method',
          return => 'result'
        }
      ],
    }
  };

  my $rewire = Rewire->new(
    services => $services,
  );

  $rewire->resolve('dynamic');

=back

=cut

=head2 validate

  validate() : Object

The validate method validates the configuration and throws an exception if
invalid, otherwise returns itself.

=over 4

=item validate example #1

  # given: synopsis

  $rewire->validate;

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/cpanery/rewire/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/cpanery/rewire/wiki>

L<Project|https://github.com/cpanery/rewire>

L<Initiatives|https://github.com/cpanery/rewire/projects>

L<Milestones|https://github.com/cpanery/rewire/milestones>

L<Contributing|https://github.com/cpanery/rewire/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/cpanery/rewire/issues>

=cut
