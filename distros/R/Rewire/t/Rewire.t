use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Rewire

=cut

=tagline

Dependency Injection

=cut

=abstract

Dependency Injection Container for Perl 5

=cut

=includes

method: config
method: process
method: resolve
method: validate

=cut

=synopsis

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

=libraries

Types::Standard

=cut

=integrates

Data::Object::Role::Buildable
Data::Object::Role::Proxyable

=cut

=attributes

context: ro, opt, CodeRef
engine: ro, opt, InstanceOf["Data::Object::Space"]
metadata: ro, opt, HashRef
services: ro, opt, HashRef

=cut

=description

This package provides methods for using dependency injection, and building
objects and values.

=cut

=scenario $callback

This package supports resolving services as callbacks to be passed around
and/or resolved by other services. The C<$callback> directive is used to
specify the name of a service to be resolved and passed as an argument.

=example $callback

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

=cut

=scenario $envvar

This package supports inlining environment variables as arguments to services.
The C<$envvar> directive is used to specify the name of an environment
variable, and can also be used in metadata for reusability.

=example $envvar

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

=cut

=scenario $function

This package supports inlining the result of a service resolution and function
call as arguments to services. The C<#> delimited C<$function> directive is
used to specify the name of an existing service on the right-hand side, and an
arbitrary function to be call on the result on the left-hand side.

=example $function

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

=cut

=scenario $metadata

This package supports inlining configuration data as arguments to services.
The C<$metadata> directive is used to specify the name of a stashed
configuration value or data structure.

=example $metadata

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

=cut

=scenario $method

This package supports inlining the result of a service resolution and method
call as arguments to services. The C<#> delimited C<$method> directive is used
to specify the name of an existing service on the right-hand side, and an
arbitrary method to be call on the result on the left-hand side.

=example $method

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

=cut

=scenario $routine

This package supports inlining the result of a service resolution and routine
call as arguments to services. The C<#> delimited C<$routine> directive is
used to specify the name of an existing service on the right-hand side, and an
arbitrary routine to be call on the result on the left-hand side.

=example $routine

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

=cut

=scenario $service

This package supports inlining resolved services as arguments to other
services. The C<$service> directive is used to specify the name of a service
to be resolved and passed as an argument.

=example $service

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

=cut

=scenario config

This package supports configuring services and metadata in the service of
building objects and values.

=example config

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

=cut

=scenario extends

This package supports extending services in the definition of other services,
recursively compiling service configurations and eventually executing the
requested compiled service.

=example extends

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

=cut

=scenario service

This package supports defining services to be constructed on-demand or
automatically on instantiation.

=example service

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

=cut

=scenario lifecycle

This package supports different lifecycle options which determine when services
are built and whether they're persisted.

=example lifecycle

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

=cut

=scenario arguments

This package supports providing static and/or dynamic arguments during object
construction from C<metadata> or other C<services>.

=example arguments

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

=cut

=scenario constructor

This package supports specifying constructors other than the traditional C<new>
routine. A constructor is always called with the package name as the invocant.

=example constructor

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

=cut

=scenario function

This package supports specifying construction as a function call, which when
called does not provide an invocant.

=example function

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

=cut

=scenario method

This package supports specifying construction as a method call, which when
called provides the package or object instance as the invocant.

=example method

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

=cut

=scenario routine

This package supports specifying construction as a function call, which when
called provides the package as the invocant.

=example routine

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

=cut

=scenario builder

This package supports specifying multiple build steps as C<function>,
C<method>, and C<routine> calls and chaining them together.

=example builder

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

=cut

=scenario metadata

This package supports specifying data and structures which can be used in the
construction of multiple services.

=example metadata

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

=cut

=scenario proxyable

This package supports the resolution of services using a single method call.
This is enabled by intercepting method calls and proxying them to the
L</process> method.

=example proxyable

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

=cut

=method config

The config method returns the configuration based on the C<services> and
C<metadata> attributes.

=signature config

config() : HashRef

=example-1 config

  # given: synopsis

  $rewire->config;

=cut

=method process

The process method processes and returns an object or value based on the
service named but where the arguments are provided ad-hoc. B<Note:> This method
is meant to be used to construct services ad-hoc and as such bypasses caching
and lifecycle effects.

=signature process

process(Str $name, Any $argument, Maybe[Str] $argument_as) : Any

=example-1 process

  # given: synopsis

  $rewire->process('tempfile', 'rewire.tmp');

=example-2 process

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

=example-3 process

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

=cut

=method resolve

The resolve method resolves and returns an object or value based on the service
named. B<Note:> This method is recommended to be used to construct services as
defined by the configuration and as such doesn't not allow passing additional
arguments.

=signature resolve

resolve(Str $name) : Any

=example-1 resolve

  # given: synopsis

  $rewire->resolve('tempfile');

=example-2 resolve

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

=example-3 resolve

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

=cut

=method validate

The validate method validates the configuration and throws an exception if
invalid, otherwise returns itself.

=signature validate

validate() : Object

=example-1 validate

  # given: synopsis

  $rewire->validate;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Mojo::File');
  ok $$result->isa('File::Temp');

  $result
});

$subs->scenario('$callback', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->validate;
  ok my $value = $result->resolve('log');
  ok $value->isa('Mojo::Log');
  my $format = $value->format;
  ok ref($format) eq 'CODE';
  my $io = $format->();
  ok $io->isa('IO::Handle');

  $result
});

$subs->scenario('$envvar', fun($tryable) {
  local $ENV{HOME} = '/home/ubuntu';

  ok my $result = $tryable->result;
  ok $result->validate;
  ok my $value = $result->resolve('file');
  ok $value->isa('Mojo::File');
  is $$value, '/home/ubuntu';

  $result
});

$subs->scenario('$function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->validate;
  ok my $value = $result->resolve('file');
  ok $value->isa('Mojo::File');
  ok $$value;

  $result
});

$subs->scenario('$metadata', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->validate;
  ok my $value = $result->resolve('file');
  ok $value->isa('Mojo::File');
  is $$value, '/home/ubuntu';

  $result
});

$subs->scenario('$method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->validate;
  ok my $value = $result->resolve('file');
  ok $value->isa('Mojo::File');
  ok $$value;

  $result
});

$subs->scenario('$routine', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->validate;
  ok my $value = $result->resolve('file');
  ok $value->isa('Mojo::File');
  ok $$value;

  $result
});

$subs->scenario('$service', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->validate;
  ok my $value = $result->resolve('log');
  ok $value->isa('Mojo::Log');
  ok $value->handle->isa('IO::Handle');

  $result
});

$subs->scenario('config', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->validate;
  ok my $value = $result->resolve('tempfile');
  ok $value->isa('Mojo::File');
  is $$value, '/home/ubuntu';

  $result
});

$subs->scenario('extends', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->validate;

  my $value;

  ok $value = $result->resolve('development_log');
  ok $value->isa('Mojo::Log');
  ok $value->handle->isa('IO::Handle');
  is $value->level, 'debug';
  is $value->path, '/tmp/development.log';

  ok $value = $result->resolve('production_log');
  ok $value->isa('Mojo::Log');
  ok $value->handle->isa('IO::Handle');
  is $value->level, 'warn';
  is $value->path, '/tmp/production.log';

  ok $value = $result->resolve('staging_log');
  ok $value->isa('Mojo::Log');
  ok $value->handle->isa('IO::Handle');
  is $value->level, 'debug';
  is $value->path, '/tmp/development.log';

  ok $value = $result->resolve('testing_log');
  ok $value->isa('Mojo::Log');
  ok $value->handle->isa('IO::Handle');
  is $value->level, 'debug';
  ok !$value->path;

  $result
});

$subs->scenario('service', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->validate;
  ok my $value = $result->context->('tempfile');
  ok $value->isa('Mojo::File');
  is $$value, '/home/ubuntu';

  $result
});

$subs->scenario('lifecycle', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->validate;
  ok my $value = $result->resolve('tempfile');
  ok $value->isa('Mojo::File');
  is $$value, '/home/ubuntu';
  ok $value = $result->context->('tempfile');
  ok $value->isa('Mojo::File');
  is $$value, '/home/ubuntu';

  $result
});

$subs->scenario('arguments', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->validate;
  ok my $value = $result->resolve('mojo_log');
  ok $value->isa('Mojo::Log');
  is $value->path, '/var/log/rewire.log';

  $result
});

$subs->scenario('constructor', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->validate;
  ok my $value = $result->resolve('mojo_date');
  ok $value->isa('Mojo::Date');

  $result
});

$subs->scenario('function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->validate;
  ok my $value = $result->resolve('foo_sum');
  is $value, 'acbd18db4cc2f85cedef654fccc4a4d8';

  $result
});

$subs->scenario('method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->validate;
  ok my $value = $result->resolve('mojo_url');
  ok $value->isa('Mojo::URL');
  is $value->host, 'perl.org';

  $result
});

$subs->scenario('routine', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->validate;
  ok my $value = $result->resolve('mojo_url');
  ok $value->isa('Mojo::URL');
  is $value->host, 'perl.org';

  $result
});

$subs->scenario('builder', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->validate;
  ok my $value = $result->resolve('mojo_date');
  ok !ref $value;
  like $value, qr/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/;

  $result
});

$subs->scenario('metadata', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->validate;
  ok my $value = $result->resolve('home');
  ok $value->isa('Mojo::Path');
  is $value->{path}, '/home';
  ok $value = $result->resolve('temp');
  ok $value->isa('Mojo::Path');
  is $value->{path}, '/tmp';

  $result
});

$subs->scenario('proxyable', fun($tryable) {
  ok my $result = $tryable->result;
  my ($home, $temp) = @$result;
  ok $home->isa('Mojo::Path');
  is $home->{path}, '/home';
  ok $temp->isa('Mojo::Path');
  is $temp->{path}, '/tmp';

  $result
});

$subs->example(-1, 'config', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {
    services => {
      filetemp => {
        package => 'File/Temp'
      },
      tempfile => {
        package => 'Mojo/File',
        argument => { '$service' => 'filetemp' }
      }
    },
    metadata => {}
  };

  $result
});

$subs->example(-1, 'process', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Mojo::File');
  is $$result, 'rewire.tmp';

  $result
});

$subs->example(-2, 'process', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Mojo::Log');
  is $result->path, '/var/log/rewire.log';
  is $result->level, 'fatal';

  $result
});

$subs->example(-3, 'process', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Mojo::Log');
  is $result->path, '/var/log/rewire.log';
  is $result->level, 'fatal';

  $result
});

$subs->example(-1, 'resolve', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Mojo::File');
  ok $$result->isa('File::Temp');

  $result
});

$subs->example(-2, 'resolve', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Mojo::Log');
  is $result->path, '/var/log/rewire.log';
  is $result->level, 'fatal';

  $result
});

$subs->example(-3, 'resolve', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Dynamic');

  $result
});

$subs->example(-1, 'validate', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
