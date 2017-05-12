# NAME

Simple::Factory - a simple factory to create objects easily, with cache, autoderef and fallback supports

# SYNOPSYS
```perl
    use Simple::Factory;

    my $factory = Simple::Factory->new(
        'My::Class' => {
            first  => { value => 1 },
            second => [ value => 2 ],
        },
        fallback => { value => undef }, # optional. in absent, will die if find no key
    );

    my $first  = $factory->resolve('first');  # will build a My::Class instance with arguments 'value => 1'
    my $second = $factory->resolve('second'); # will build a My::Class instance with arguments 'value => 2'
    my $last   = $factory->resolve('last');   # will build a My::Class instance with fallback arguments
```
# DESCRIPTION

This is one way to implement the [Factory Pattern](http://www.oodesign.com/factory-pattern.html). The main objective is substitute one hashref of objects ( or coderefs who can build/return objects ) by something more intelligent, who can support caching and fallbacks. If the creation rules are simple we can use `Simple::Factory` to help us to build instances.

We create instances with `resolve` method. It is lazy. If you need build all instances (to store in the cache) consider try to resolve them first.

If you need something more complex, consider some framework of Inversion of Control (IoC).

For example, we can create a simple factory to create DateTime objects, using CHI as cache:
```perl
     my $factory = Simple::Factory->new(
          build_class  => 'DateTime',
          build_method => 'from_epoch',
          build_conf   => {
              one      => { epoch => 1 },
              two      => { epoch => 2 },
              thousand => { epoch => 1000 }
          },
          fallback => sub { epoch => $_[0] }, # fallback can receive the key
          cache    => CHI->new( driver => 'Memory', global => 1),
      );

    $factory->resolve( 1024 )->epoch # returns 1024
```
IMPORTANT: if the creation fails ( like some excetion from the constructor ), we will **not** call the `fallback`. 
Check ["on\_error"](#on_error) attribute to change the default behavior.

# ATTRIBUTES

## build\_class

Specify the perl package ( class ) used to create instances. Using `Method::Runtime`, will die if can't load the package.

This argument is required. You can omit by using the `build_class` as a first argument of the constructor.

## build\_args

Specify the mapping of key => arguments, storing in a hashref.

This argument is required. You can omit by using the `build_class` and `build_args` as a first pair of arguments.

Important: if `autoderef` is true, we will try to deref the value before use to create an instance. 

## fallback

The default behavior is die if we try to resolve an instance using one non-existing key.

But if fallback is present, we will use this on the constructor.

If `autoderef` is true and fallback is a code reference, we will call the code and pass the key as an argument.

## build\_method

By default the `Simple::Factory` calls the method `new` but you can override and specify your own build method.

Will croak if the `build_class` does not support the method on `resolve`.

## autoderef

If true ( default ), we will try to deref the argument present in the `build_conf` only if it follow this rules:

- will deref only references
- if the reference is an array, we will call the `build_method` with `@$array`.  
- if the reference is a hash, we will call the `build_method` with `%$hash`.
- if the reference is a scalar or other ref, we will call the `build_method` with `$$ref`.
- if the reference is a glob, we will call the `build_method` with `*$glob`.
- if the reference is a code, we will call the `build_method` with $code->( $key ) ( same thinf for the fallback )
- other cases (like Regexes) we will carp if it is not in `silence` mode. 

## silence

If true ( default is false ), we will omit the carp message if we can't `autoderef`.

## cache

If present, we will cache the result of the method `resolve`. The cache should responds to `get`, `set` and `remove` like [CHI](https://metacpan.org/pod/CHI).

We will also cache fallback cases. The key used on the cache is `build_class`:`key`, to be possible share the same cache with many factories.

If we need add a new build\_conf via `add_build_conf_for`, and override one existing configuration, we will remove it from the cache if possible.

default: not present

## inline 

**Experimental** feature. useful to create multiple inline definitions. See ["resolve"](#resolve) method.

This feature can change in the future.

## eager

If true, will force `resolve` all configure keys when build the object. Useful to force caching all of them.

default: false.

## on\_error

Change the default behavior of what happens if build one instance throws on error.

Accepts a coderef. You can also use three initial shortcuts ( will be coerce to coderef ): `croak`, `carp`, `confess`, `fallback` and `undef`.

- `croak` will croak the exception + extra message about the key ( **default** ).
- `confess` will confess, instead croak the exception.
- `carp` will just carp instead croak and return undef.
- `fallback` will resolve the fallback ( but in case of exception will die - to avoid one potential deadlock ).
- `undef` will return an undefined value.

Example:
```perl
    my $factory = Simple::Factory->new(
        Foo => { ... },
        fallback => -1,
        on_error => "fallback" # in case of some exception, call the fallback
    );
```
If one coderef was used, it will be called with one hashref as argument with three fields:

- `key` with the value of the key 
- `factory` one reference for the factory itself
- `exception` with the error message

Example:
```perl
    my $factory =  Simple::Factory->new(
        Foo => { a => 1 },
        on_error => sub { $logger->warn("error while resolve key '$_[0]->{key}' : '$_[0]->{exception}'; undef },
    );

    $factory->resolve("b"); # will call 'on_error', log the exception and return undef
```
# METHODS

## add\_build\_conf\_for

usage: add\_build\_conf\_for( key => configuration \[, options \])

Can add a new build configuration for one specific key. It is possible add new or just override.

You can change the behavior using an hash of options. 

Options: you can avoid override one existing configuration with `not_override` and a true value.

Will remove `cache` if possible.

Example:
```perl
    $factory->add_build_conf_for( last => { foo => 1, bar => 2 }); # can override
    $factory->add_build_conf_for( last => { ... }, not_override => 1); # will croak instead override
```
## resolve

usage: resolve( key \[, keys \] )

The main method. Will build one instance of `build_class` using the `build_conf` and `build_method`. 

Should receive a key and if does not exist a `build_conf` will try use the fallback if specified, or will die ( confess ).

If the `cache` attribute is present, will try to return first one object from the cache using the `key`, or will resolve and
store in the cache for the next call.

You can pass multiple keys. If the instance responds to `resolve` method, we will call with the rest of the keys. It is useful
for inline many factories.

Example:
```perl
    my $factory = Simple::Factory->new(
        'Simple::Factory' => {
            Foo => {
                build_class => 'Foo',
                build_conf => {
                    one => 1,
                    two => 2,
                }
            },
            Bar => {
                Bar => {
                    first => { ... },
                    last => { ... },
                }
            }
        }
    );

    my $object = $factory->resolve('Foo', 'one'); # shortcut to ->resolve('Foo')->resolve('one');
```
Or, using `inline` experimental option.
```perl
    my $factory = Simple::Factory->new(
        'Simple::Factory'=> {
            Foo => { one => 1, two => 2 },
            Bar => { first => 0, last => -1},
        },
        inline => 1,
    );
```
If we have some exception when we try to create an instance for one particular key, we will not call the `fallback`. 
We use `fallback` when we can't find the `build_conf` based on the key. 

To change the behavior check the attr `on_error`.

## get\_fallback\_for\_key 

this method will try to resolve the fallback. can be useful on `on_error` coderefs. accept the same argument as `resolve`.

# SEE ALSO

- [Bread::Board](https://metacpan.org/pod/Bread::Board)

    A solderless way to wire up your application components.

- [IOC](https://metacpan.org/pod/IOC)

    A lightweight IOC (Inversion of Control) framework

# LICENSE

The MIT License

    Permission is hereby granted, free of charge, to any person
    obtaining a copy of this software and associated
    documentation files (the "Software"), to deal in the Software
    without restriction, including without limitation the rights to
    use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to
    whom the Software is furnished to do so, subject to the
    following conditions:
     
     The above copyright notice and this permission notice shall
     be included in all copies or substantial portions of the
     Software.
      
      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
      WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
      INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
      MERCHANTABILITY, FITNESS FOR A PARTICULAR
      PURPOSE AND NONINFRINGEMENT. IN NO EVENT
      SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
      LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
      LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
      TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
      CONNECTION WITH THE SOFTWARE OR THE USE OR
      OTHER DEALINGS IN THE SOFTWARE.

# AUTHOR

Tiago Peczenyj <tiago (dot) peczenyj (at) gmail (dot) com>

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/peczenyj/simple-factory-p5/issues](https://github.com/peczenyj/simple-factory-p5/issues)
