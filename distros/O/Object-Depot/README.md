# NAME

Object::Depot - Decouple object instantiation from usage.

# SYNOPSIS

```perl
use Object::Depot;

my $depot = Object::Depot->new(
    class => 'CHI',
    # CHI->new returns a CHI::Driver object.
    type => InstanceOf[ 'CHI::Driver' ],
);

$depot->add_key(
    sessions => {
        driver => 'Memory',
        global => 1,
    },
);

$depot->store( ip2geo => CHI->new(...) );

my $sessions = $depot->fetch('sessions');
my $ip2geo = $depot->fetch('ip2geo');
```

# DESCRIPTION

Object depots encapsulate object construction so that users of objects
do not need to know how to create the objects in order to use them.

The primary use case for this library is for storing the connection
logic to external services and making these connections globally
available to all application logic.  See [Object::Depot::Role](https://metacpan.org/pod/Object%3A%3ADepot%3A%3ARole) for
turning your depot object into a global singleton.

# ARGUMENTS

## class

```perl
class => 'CHI',
```

The class which objects in this depot are expected to be.  This
argument defaults the ["constructor"](#constructor) and ["type"](#type) arguments.

Does not have a default.

Leaving this argument unset causes ["fetch"](#fetch) to fail on keys that were
not first populated with ["store"](#store) as the ["constructor"](#constructor) subroutine
will just return `undef`.

## constructor

```perl
constuctor => sub{
    my ($args) = @_;
    return __PACKAGE__->depot->class->new( $args );
},
```

Set this to a code ref to control how objects get constructed.

When declaring a custom constructor be careful not to create memory
leaks via circular references.

["create"](#create) validates the objects produced by this constructor and will
throw an exception if they do not match ["type"](#type).

The default code ref is similar to the above example if ["class"](#class) is
set.  If it is not set then the default code ref will return `undef`.

## type

```perl
type => InstanceOf[ 'CHI::Driver' ],
```

Set this to a [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny) type to control how objects in the depot
are validated when they are stored.

Defaults to `InstanceOf` ["class"](#class), if set.  If the class is not set
then this defaults to `Object` (both are from [Types::Standard](https://metacpan.org/pod/Types%3A%3AStandard)).

## injection\_type

```perl
injection_type => Object,
```

By default objects that are injected (see ["inject"](#inject)) are validated
against ["type"](#type).  Set this to a type that injections validate
against if it needs to be different (such as to support mock
objects).

## per\_process

```perl
per_process => 1,
```

Turn this on to store objects per-process; meaning, if the TID (thread
ID) or PID (process ID) change then this depot will act as if no
objects have been stored.  Generally you will not want to turn this
on.  On occasion, though, some objects are not thread or forking safe
and it is necessary.

Defaults off.

## disable\_store

```perl
disable_store => 1,
```

When on this causes ["store"](#store) to silently not store, causing all
["fetch"](#fetch) calls for non-injected keys to return a new object.

Defaults off.

## strict\_keys

```perl
strict_keys => 1,
```

Turn this on to require that all keys used must first be declared
via ["add\_key"](#add_key) before they can be stored in the depot.

Defaults to off, meaning keys may be used without having to
pre-declare them.

## default\_key

```perl
default_key => 'generic',
```

If no key is passed to key-accepting methods like ["fetch"](#fetch) then they
will use this default key if available.

Defaults to no default key.

## key\_argument

```perl
key_argument => 'connection_key',
```

When set, this causes ["arguments"](#arguments) to include an extra argument to be
passed to the class during object construction.  The argument's key
will be whatever you set this to and the value will be the key used to
fetch the object.

You will still need to write the code in your class to capture the
argument, such as:

```perl
has connection_key => ( is=>'ro' );
```

Defaults to no key argument.

## default\_arguments

```perl
default_arguments => {
    arg => 'value',
    ...
},
```

When set, these arguments will be included in calls to ["arguments"](#arguments).

Defaults to an empty hash ref.

## export\_name

```perl
export_name => 'myapp_cache',
```

Set the name of a function that [Object::Depot::Role](https://metacpan.org/pod/Object%3A%3ADepot%3A%3ARole) will
export to importers of your depot package.

Has no default.  If this is not set, then nothing will be exported.

## always\_export

```perl
always_export => 1,
```

Turning this on causes [Object::Depot::Role](https://metacpan.org/pod/Object%3A%3ADepot%3A%3ARole) to always export
the ["export\_name"](#export_name), rather than only when listed in the import
arguments. This is synonymous with the difference between
[Exporter](https://metacpan.org/pod/Exporter)'s `@EXPORT_OK` and `@EXPORT`.

# METHODS

## active\_objects

```perl
my @objects = $depot->active_objects();
```

Return an array containing all active objects the depot created via calls to $depot->create().

If per\_process is set, returns only active objects created by the current process/thread.

## fetch

```perl
my $object = $depot->fetch( $key );
```

## store

```perl
$depot->store( $key => $object );
```

## remove

```
$depot->remove( $key );
```

## create

```perl
my $object = $depot->create( $key, %extra_args );
```

Gathers arguments from ["arguments"](#arguments) and then calls ["constructor"](#constructor)
on them, returning a new object.  Extra arguments may be passed and
they will take precedence.

## arguments

```perl
my $args = $depot->arguments( $key, %extra_args );
```

This method returns an arguments hash ref that would be used to
instantiate a new ["class"](#class) object. You could, for example, use this
to produce a base-line set of arguments, then sprinkle in some more,
and make yourself a special mock object to be injected.

## declared\_keys

```perl
my $keys = $depot->declared_keys();
foreach my $key (@$keys) { ... }
```

Returns an array ref containing all the keys declared with
["add\_key"](#add_key).

## inject

```
$depot->inject( $key, $object );
```

Takes an object of your making and forces ["fetch"](#fetch) to return the
injected object.  This is useful for injecting mock objects in tests.

The injected object must validate against ["type"](#type).

## inject\_with\_guard

```perl
my $guard = $depot->inject_with_guard( $key => $object );
```

This is just like ["inject"](#inject) except it returns a [Guard](https://metacpan.org/pod/Guard) object
which, when it leaves scope and is destroyed, will automatically
call ["clear\_injection"](#clear_injection).

## clear\_injection

```perl
my $object = $depot->clear_injection( $key );
```

Removes and returns the injected object, restoring the original
behavior of ["fetch"](#fetch).

## injection

```perl
my $object = $depot->injection( $key );
```

Returns the injected object, or `undef` if none has been injected.

## has\_injection

```
if ($depot->has_injection( $key )) { ... }
```

Returns true if an injection is in place for the specified key.

## add\_key

```
$depot->add_key( $key, %arguments );
```

Declares a new key and, optionally, the arguments used to construct
the ["class"](#class) object.

Arguments are optional, but if present they will be saved and used
by ["fetch"](#fetch) when calling `new()` (via ["arguments"](#arguments)) on ["class"](#class).

## alias\_key

```perl
$depot->alias_key( $alias_key => $real_key );
```

Adds a key that is an alias to another key.

# SUPPORT

Please submit bugs and feature requests to the Object-Depot GitHub issue tracker:

[https://github.com/bluefeet/Object-Depot/issues](https://github.com/bluefeet/Object-Depot/issues)

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/) for encouraging their employees to
contribute back to the open source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

# AUTHORS

```
Aran Clary Deltac <bluefeet@gmail.com>
```

# LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
