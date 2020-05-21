package Rewire::Engine;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Space;

use Scalar::Util ();

# FUNCTIONS

# returns the json-schema-based engine ruleset
fun ruleset() {

  state $ruleset = require Rewire::Ruleset;
}

# returns context closure
fun context() {
  my $cache = {};

  fun(Str $name, Any $object) {

    return $cache->{$name} = $object if $object;
    return $cache->{$name};
  }
}

# returns context with eager-loaded objects
fun preload(HashRef $servConf, Maybe[CodeRef] $context) {
  $context = context() if !$context;

  if (my $servSpec = $servConf->{services}) {
    for my $name (keys %$servSpec) {
      next if $context->($name);

      my $service = $servSpec->{$name};
      my $lifecycle = $service->{lifecycle};

      next if !$lifecycle;

      if ($lifecycle eq 'eager') {
        $context->($name, reifier($name, $servConf, $context));
      }
    }
  }

  $context;
}

# builds and returns object or value based on spec
fun builder(HashRef $service, Any $argument, Maybe[Object] $construct) {
  my $space = Data::Object::Space->new($service->{package});

  # load declared package
  $space->load;

  # determine how to pass arguments (if any)
  my @arguments = arguments($argument, $service->{argument_as});

  # determine construction
  if (my $builder = $service->{builder}) {
    my $original;

    # inject at last build step unless arguments exist
    my @injectables = @arguments;

    for (my $i=0; $i < @$builder; $i++) {
      my $buildspec = $builder->[$i];
      my $argument = $buildspec->{argument};
      my $argument_as = $buildspec->{argument_as};
      my $return = $buildspec->{return};

      my $result = $construct || $space->package;
      my @arguments = arguments($argument, $argument_as);

      if ($i == $#$builder) {
        # on last build step if no build step arguments
        @arguments = @injectables if not exists $buildspec->{argument};
      }

      if (my $function = $buildspec->{function}) {
        $result = $space->call($function, @arguments);
      }
      elsif (my $method = $buildspec->{method}) {
        $result = $space->call($method, $result, @arguments);
      }
      elsif (my $routine = $buildspec->{routine}) {
        $result = $space->call($routine, $space->package, @arguments);
      }
      else {
        next;
      }

      if ($return eq 'class') {
        $construct = $space->package;
      }
      if ($return eq 'result') {
        $construct = $result;
      }
      if ($return eq 'self') {
        $construct = $original //= $result;
      }
    }
  }
  elsif (my $method = $service->{method}) {
    $construct = $space->package->$method(@arguments);
  }
  elsif (my $function = $service->{function}) {
    $construct = $space->call($function, @arguments);
  }
  elsif (my $routine = $service->{routine}) {
    $construct = $space->call($routine, $space->package, @arguments);
  }
  elsif (my $constructor = $service->{constructor}) {
    $construct = $space->package->$constructor(@arguments);
  }
  else {
    $construct = $space->build(@arguments);
  }

  $construct;
}

# returns invoked object or value based on service name
fun reifier(Str $servName, HashRef $servConf, Maybe[CodeRef] $context) {
  $context = preload($servConf) if !$context;

  my $value;
  my $service;
  my $extended;

  my $servSpec = $servConf->{services};

  # use cached (if any)
  $service = $context->($servName);

  return $service if $service;

  $service = $servSpec->{$servName} or return;

  # extend existing service (if requested)
  if (my $extends = $service->{extends}) {
    $extended = reifier($extends, $servConf, $context);
  }

  # build object or value
  my $arguments = resolver($service->{argument}, $servConf, $context);

  $value = builder($service, $arguments, $extended);

  # determine cachability
  my $lifecycle = $service->{lifecycle};

  if ($lifecycle && $lifecycle eq 'singleton') {
    $context->($servName, $value);
  }

  return $value;
}

# resolves service spec arguments
fun resolver(Any $argsData, HashRef $servConf, Maybe[CodeRef] $context) {
  my $servMeta = $servConf->{metadata};
  my $servSpec = $servConf->{services};

  if (ref $argsData eq 'ARRAY') {
    $argsData = [map resolver($_, $servConf, $context), @$argsData];
  }

  # $metadata
  if (ref $argsData eq 'HASH' && (keys %$argsData) == 1) {
    if ($servMeta && $argsData->{'$metadata'}) {
      $argsData = $servMeta->{$argsData->{'$metadata'}};
    }
  }

  # $envvar
  if (ref $argsData eq 'HASH' && (keys %$argsData) == 1) {
    if (my $envvar = $argsData->{'$envvar'}) {
      if (exists $ENV{$envvar}) {
        $argsData = $ENV{$envvar};
      }
      elsif (exists $ENV{uc($envvar)}) {
        $argsData = $ENV{uc($envvar)};
      }
      else {
        $argsData = undef;
      }
    }
  }

  # $function
  if (ref $argsData eq 'HASH' && (keys %$argsData) == 1) {
    if ($servSpec && $argsData->{'$function'}) {
      my ($name, $next) = split /#/, $argsData->{'$function'};
      if ($name && $next) {
        if (my $resolved = reifier($name, $servConf, $context)) {
          if (Scalar::Util::blessed($resolved)
            || (!ref($resolved) && ($resolved =~ /^[a-z-A-Z]/))) {
            my $space = Data::Object::Space->new(ref $resolved || $resolved);
            $argsData = $space->call($next) if $next && $next =~ /^[a-zA-Z]/;
          }
        }
      }
    }
  }

  # $method
  if (ref $argsData eq 'HASH' && (keys %$argsData) == 1) {
    if ($servSpec && $argsData->{'$method'}) {
      my ($name, $next) = split /#/, $argsData->{'$method'};
      if ($name && $next) {
        if (my $resolved = reifier($name, $servConf, $context)) {
          if (Scalar::Util::blessed($resolved)
            || (!ref($resolved) && ($resolved =~ /^[a-z-A-Z]/))) {
            $argsData = $resolved->$next if $next && $next =~ /^[a-zA-Z]/;
          }
        }
      }
    }
  }

  # $routine
  if (ref $argsData eq 'HASH' && (keys %$argsData) == 1) {
    if ($servSpec && $argsData->{'$routine'}) {
      my ($name, $next) = split /#/, $argsData->{'$routine'};
      if ($name && $next) {
        if (my $resolved = reifier($name, $servConf, $context)) {
          if (Scalar::Util::blessed($resolved)
            || (!ref($resolved) && ($resolved =~ /^[a-z-A-Z]/))) {
            my $space = Data::Object::Space->new(ref $resolved || $resolved);
            $argsData = $space->call($next) if $next && $next =~ /^[a-zA-Z]/;
          }
        }
      }
    }
  }

  # $service
  if (ref $argsData eq 'HASH' && (keys %$argsData) == 1) {
    if ($servSpec && $argsData->{'$service'}) {
      $argsData = reifier($argsData->{'$service'}, $servConf, $context);
    }
  }

  if (ref $argsData eq 'HASH' && grep ref, values %$argsData) {
    @$argsData{keys %$argsData} = map resolver($_, $servConf, $context), values %$argsData;
  }

  return $argsData;
}

# returns a list of arguments for object construction
fun arguments(Any $argument, Any $argument_as) {
  my @arguments;

  if ($argument && $argument_as) {
    if ($argument_as eq 'array') {
      if (ref $argument eq 'HASH') {
        @arguments = ([$argument]);
      }
      else {
        @arguments = ($argument);
      }
    }
    if ($argument_as eq 'hashmap') {
      if (ref $argument eq 'ARRAY') {
        @arguments = ({@$argument});
      }
      else {
        @arguments = ($argument);
      }
    }
    if ($argument_as eq 'list') {
      if (ref $argument eq 'ARRAY') {
        @arguments = (@$argument);
      }
      elsif (ref $argument eq 'HASH') {
        @arguments = (%$argument);
      }
      else {
        @arguments = ($argument);
      }
    }
  }
  else {
    @arguments = ($argument) if defined $argument;
  }

  (@arguments);
}

1;
