# NAME

Minions - Simplifies the creation of loosely coupled object oriented code.

# SYNOPSIS

    # Imagine a counter used like this:

    use Test::Most tests => 5;
    use Example::Synopsis::Counter;

    my $counter = Example::Synopsis::Counter->new;

    is $counter->next => 0;
    is $counter->next => 1;
    is $counter->next => 2;

    throws_ok { $counter->new } qr/Can't locate object method "new"/;

    throws_ok { Example::Synopsis::Counter->next }
              qr/Can't locate object method "next" via package "Example::Synopsis::Counter"/;


    # The counter class:

    package Example::Synopsis::Counter;

    use Minions
        interface => [ qw( next ) ],

        implementation => 'Example::Synopsis::Acme::Counter';

    1;


    # And the implementation for this class:

    package Example::Synopsis::Acme::Counter;

    use Minions::Implementation
        has => {
            count => { default => 0 },
        }
    ;

    sub next {
        my ($self) = @_;

        $self->{$COUNT}++;
    }

    1;

# STATUS

This module is now deprecated. Please use [Mic](https://metacpan.org/pod/Mic) instead. 

# DESCRIPTION

Minions is a class builder that makes it easy to create classes that are [modular](http://en.wikipedia.org/wiki/Modular_programming), which means
there is a clear and obvious separation between what end users need to know (the interface for using the class) and implementation details that users
don't need to know about.

Classes are built from a specification that declares the interface of the class (i.e. what commands instances of the classs respond to),
as well as a package that provide the implementation of these commands.

This separation of interface from implementation details is an important aspect of modular design, as it enables modules to be interchangeable (so long as they have the same interface).

It is not a coincidence that the Object Oriented concept as originally envisioned was mainly concerned with messaging,
where in the words of Alan Kay (who coined the term "Object Oriented Programming") objects are "like biological cells and/or individual computers on a network, only able to communicate with messages"
and "OOP to me means only messaging, local retention and protection and hiding of state-process, and extreme late-binding of all things."
(see [The Deep Insights of Alan Kay](http://mythz.servicestack.net/blog/2013/02/27/the-deep-insights-of-alan-kay/)).

# RATIONALE

Due to Perl's "assembly required" approach to OOP, there are many CPAN modules that exist to automate this assembly,
perhaps the most popular being the [Moose](https://metacpan.org/pod/Moose) family. Although Moo(se) is very effective at simplifying class building, this is typically achieved at the
expense of [Encapsulation](https://en.wikipedia.org/wiki/Information_hiding) (because Moose encourages the exposure of all an object's attributes via methods), and this in turn encourages
designs that are tightly [coupled](https://en.wikipedia.org/wiki/Coupling_\(computer_programming\)).

To see this first hand, try writing the fixed size queue from ["OBJECT COMPOSITION" in Minions::Implementation](https://metacpan.org/pod/Minions::Implementation#OBJECT-COMPOSITION) using [Moo](https://metacpan.org/pod/Moo), bearing in mind that the only operations the queue should allow are `push`, `pop` and `size`. It is also a revealing exercise to consider how this queue would be written in another language such as Ruby or PHP (e.g. would you need to expose all object attributes via methods?). 

Minions takes inspriation from Moose's declaratve approach to simplifying OO automation, but also aims to put encapsulation and loose coupling on the path of least resistance.

## The Tale of Minions

The following fable illustrates the main ideas of OOP.

There once was a farmer who had a flock of sheep. His typical workday looked like:

    $farmer->move_flock($pasture)
    $farmer->monitor_flock()
    $farmer->move_flock($home)

    $farmer->other_important_work()

In order to devote more time to `other_important_work()`, the farmer decided to hire a minion, so the work was now split like this:

    $shepherd_boy->move_flock($pasture)
    $shepherd_boy->monitor_flock()
    $shepherd_boy->move_flock($home)

    $farmer->other_important_work()

This did give the farmer more time for `other_important_work()`, but unfornately `$shepherd_boy` had a tendency to [cry wolf](http://en.wikipedia.org/wiki/The_Boy_Who_Cried_Wolf) so the farmer had to replace him:

    $sheep_dog->move_flock($pasture)
    $sheep_dog->monitor_flock()
    $sheep_dog->move_flock($home)

    $farmer->other_important_work()

`$sheep_dog` was more reliable and demanded less pay than `$shepherd_boy`, so this was a win for the farmer.

### Ideas

Object Oriented design is essentially the act of minionization, i.e. deciding which minions (objects) will do what work, and how to communicate with them (using an interface).

The most important ideas are

#### Delegation

To handle complexity, delegate to a suitable entity e.g. the farmer delegates some of his work to `$shepherd_boy` (and later on to `$sheep_dog`).

#### Encapsulation

We tell objects what to do, rather than micro-manage e.g.

    $sheep_dog->monitor_flock();

rather than

    $sheep_dog->{brain}{task}{monitor_flock} = 1;

At a high level, we do not particularly care what the internals of the object are. We only care what the object can do.

But, an object becomes harder to change the more its internals are exposed.

#### Polymorphism

`$sheep_dog` and `$shepherd_boy` both understood the same commands, so replacing the latter with the former was easier than it would have been otherwise.

# USAGE

## Via Import

A class can be defined when importing Minions e.g.

    package Foo;

    use Minions
        interface => [ qw( list of methods ) ],

        construct_with => {
            arg_name => {
                assert => {
                    desc => sub {
                        # return true if arg is valid
                        # or false otherwise
                    }
                },
                optional => $boolean,
            },
            # ... other args
        },

        implementation => 'An::Implementation::Package',
        ;
    1;

## Minions->minionize(\[HASHREF\])

A class can also be defined by calling the `minionize()` class method, with an optional hashref that
specifies the class.

If the hashref is not given, the specification is read from a package variable named `%__meta__` in the package
from which `minionize()` was called.

The class defined in the SYNOPSIS could also be defined like this

    use Test::More tests => 2;
    use Minions ();

    my %Class = (
        name => 'Counter',
        interface => [qw( next )],
        implementation => {
            methods => {
                next => sub {
                    my ($self) = @_;

                    $self->{-count}++;
                }
            },
            has  => {
                count => { default => 0 },
            },
        },
    );

    Minions->minionize(\%Class);
    my $counter = Counter->new;

    is $counter->next => 0;
    is $counter->next => 1;

_This example was included for completeness. Creating a class this way is not recommended for real world
projects as it doesn't scale up as well as the mainstream usage (i.e. using separate packages)._

## Specification

The meaning of the keys in the specification hash are described next.

### interface => ARRAYREF

A reference to an array containing the messages that minions belonging to this class should respond to.
An exception is raised if this is empty or missing.

The messages named in this array must have corresponding subroutine definitions in a declared implementation,
otherwise an exception is raised.

### construct\_with => HASHREF

An optional reference to a hash whose keys are the names of keyword parameters that are passed to the default constructor.

The values these keys are mapped to are themselves hash refs which can have the following keys.

See [Minions::Manual::Construction](https://metacpan.org/pod/Minions::Manual::Construction) for more about construction.

#### optional => BOOLEAN (Default: false)

If this is set to a true value, then the corresponding key/value pair need not be passed to the constructor.

#### assert => HASHREF

A hash that maps a description to a unary predicate (i.e. a sub ref that takes one value and returns true or false).
The default constructor will call these predicates to validate the parameters passed to it.

### implementation => STRING | HASHREF

The name of a package that defines the subroutines declared in the interface.

Alternatively an implementation can be hashref as shown in the synopsis above.

[Minions::Implementation](https://metacpan.org/pod/Minions::Implementation) describes how implementations are configured.

## Bindings

The implementation of a class can be quite easily changed from user code e.g. after

    use Minions
        bind => { 
            'Foo' => 'Foo::Fake', 
            'Bar' => 'Bar::Fake', 
        };
    use Foo;
    use Bar;

Foo and bar will be bound to fake implementations (e.g. to aid with testing), instead of the implementations defined in
their respective modules.

## Introspection

Behavioural and Role introspection are possible using `$object->can` and `$object->DOES` which if called with no argument will return a list (or array ref depending on context) of methods or roles respectiively supported by the object.

See the section "Using multiple roles" from ["EXAMPLES" in Minions::Role](https://metacpan.org/pod/Minions::Role#EXAMPLES) for an example.

Also note that for any class `Foo` created using Minions, and for any object created with `Foo`'s constructor, the following will always return a true value

    $object->DOES('Foo')

# BUGS

Please report any bugs or feature requests via the GitHub web interface at
[https://github.com/arunbear/minions/issues](https://github.com/arunbear/minions/issues).

# ACKNOWLEDGEMENTS

Stevan Little (for creating Moose), Tye McQueen (for numerous insights on class building and modular programming).

# AUTHOR

Arun Prasaad <arunbear@cpan.org>

# COPYRIGHT

Copyright 2014- Arun Prasaad

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU public license, version 3.

# SEE ALSO
