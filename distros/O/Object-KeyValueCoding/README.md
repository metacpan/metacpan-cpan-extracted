# NAME

Object::KeyValueCoding - Perl implementation of Key-Value Coding

# SYNOPSIS

    package Foo;
    use Object::KeyValueCoding;

    ...

    my $o = Foo->new();
    $o->setBar("quux");
    ...
    print $o->valueForKey("bar");
    quux

See more complex examples below.



# VERSION

    0.94



# FEATURES

- Easy to add to your project

Lots of different ways to do this... see below.

- Production-tested

Ran on a high-volume website for 10 years.

- Familiar format to iOS/OSX/WebObjects developers

The basic API is really similar to NSKeyValueCoding.

- Almost entirely dependency-free.

Not going to bloat your project.



# DESCRIPTION

One of the greatest things about developing using the NeXT/Apple toolchain
is the consistent use of something called key-value coding.  It's the kind
of thing that, once you buy into its philosophy, will suddenly make a whole
slew of things easier for you in ways that you never thought of before.
Every time I move to a new platform, be it Python or Javascript or Perl,
I always find myself frustrated by its absence, and find myself jumping
through all kinds of stupid hoops just to do things that would be dead-simple
if key-value coding were available to me.

So here is a Perl implementation of KVC that you can
glom onto your objects, or even glom onto everything in your system,
and KVC will be available in all its glory (well, some of its glory...
see below).





# USAGE

If you just do this in a class:

    use Object::KeyValueCoding;

it will add key-value coding methods to that class.  You don't
need to fiddle with your inheritance.  Subclasses of your class will
inherit key-value coding methods.

At present, you can choose between two different implementations, "simple",
(which only implements the very basics of key-value coding and key-path
traversal) or "complex" (which has much more powerful object graph traversal
capabilities).  You can do it like this:

    use Object::KeyValueCoding implementation => "simple";

If you don't indicate an implementation, the default ("complex") will be
used.

You can also add the optional "additions" (see below) like this:

    use Object::KeyValueCoding additions => 1;

which will add a number of helper methods into the resolution chain
of the "complex" implementation.

You can also indicate a "target", which is the name of a class in
which to install key-value coding.  You will generally not use this, but
you could conceivably use it to install key-value coding system-wide:

    use Object::KeyValueCoding target => "UNIVERSAL";

Purists' heads might explode at this idea, but it's not so strange - it's
essentially how the NSKeyValueCoding "category" works in Objective-C.

## Moose

If you're using Moose, you might prefer to use Object::KeyValueCoding::Role,
which will do what it's supposed to and add the key-value coding methods
into your class.





# METHODS

All implementations of KVC must support these methods:

    valueForKey( <key> )
    valueForKeyPath( <keypath> )
    setValueForKey( <value>, <key> )
    setValueForKeyPath( <value>, <keypath> )



Any KVC-aware objects will now response to those methods.
( Note: the difference between a key-path and a key is that a key-path can
be an arbitrarily long dot-path of keys ).

Here is an example session that should show how it works:

    > re.pl
    $ package Foo;
      use base qw( Object::KeyValueCoding );
      sub new { return bless $_[1] }
    $ my $foo = Foo->new({ bar => "This is foo.bar",
                           baz => { quux => "This is foo.baz.quux",
                           bonk => [ 'This is foo.baz.bonk.@0', 'This is foo.baz.bonk.@1' ]
                       }});
    Foo=HASH(0x1020576c0);
    $ $foo->valueForKey("bar")
    This is foo.bar
    $ $foo->valueForKeyPath("baz.quux")
    This is foo.baz.quux
    $ $foo->valueForKeyPath('baz.bonk.@1')
    This is foo.baz.bonk.@1
    $

If a function is found rather than a property, it will
be called in the context of the object it belongs to:



    sub Foo::bing {
        return [ 'This is foo.bing.@0', 'and this is foo.bing.@1' ];
    }
    $ $foo->valueForKey('bing.@1')
    'and this is foo.bing.@1'
    $



The implementation allows nested key-paths, which are turned into arguments:



    $ sub Foo::bong { my ($self, $bung) = @_; return uc($bung) }
    $ $foo->valueForKey("baz.quux")
    This is foo.baz.quux
    $ $foo->valueForKey("bong(baz.quux)")
    THIS IS FOO.BAZ.QUUX
    $ $foo->valueForKey("self.bong(self.baz.quux)")
    THIS IS FOO.BAZ.QUUX
    $

    See how it traverses the object graph from one related object to
    another:

    $ package Goo; use base qw( Object::KeyValueCoding ); sub new { bless $_[1] }
    $ my $goo = Goo->new({ something => $foo, name => "I'm called Goo!" });
    Goo=HASH(0x1020763d8);
    $ $goo->valueForKey("something.bong(name)")
    I'M CALLED GOO!
    $ $goo->valueForKey("something.bong(self.name)")
    I'M CALLED GOO!
    $ $goo->valueForKey("self.something.bong(self.name)")
    I'M CALLED GOO!
    $



The corresponding `set` methods, `setValueForKey` and `setValueForKeyPath`
will set the value on whatever object the key/keypath resolves to.
If any part of the key or keypath returns *null*, the call will
(at present) fail silently.  __NOTE:__ This is not the same behaviour
as Apple's NSKeyValueCoding; it's a bit more like the Clojure
"thread" operator (->>).



# EXTRA STUFF

The implementation has some optional "additions" that you can use.
What are these "additions"?  They provide a number of "special" methods
that can be used in keypaths:

    eq(a, b)
    not( a )
    and( a, b )
    or( a, b )
    commaSeparatedList( a )
    truncateStringToLength( a, l )
    sorted( a )
    reversed( a )
    keys( a )
    length( a )
    int( a )

For example:

    $ my $goo = Goo->new({ a => 1, b => 0, c => 0 });
    Goo=HASH(0x1020633d0);
    $ $goo->valueForKey("and(a, b)")
    0
    $ $goo->valueForKey("or(a, b)")
    1
    $ $goo->valueForKey("or(b, c)")
    0
    $

Note that the arguments themselves can be arbitrarily long key-paths.



# TODO

- Better support for Moose/Mouse

Since Moose is pretty much the defacto way now of doing OO
in Perl, KVC should detect Moose and play nicer with it. The 1.0
release of this package will include support for Moose/Mouse
by using Class::MOP to perform introspection on objects and
access attributes.

- Allow consumer to specify naming conventions

So when you attach KVC methods, you can specify if they're
value_for_key or valueForKey.  Also, so the consumer can
tell the KVC system how accessors are named.



# HISTORY

This implementation originated as part of the Idealist Framework
(https://github.com/quile/if-framework) over 10 years
ago.  It was loosely based on the NSKeyValueCoding protocol found
on NeXTStep/OpenStep (at that time) and now Cocoa/iOS.  This is the
reason why the code is a bit hairy - its very old (predating pretty much
every advance in Perl...).  But that works in its favour, because it
means it will work well with most Perl objects and isn't bound to
an OO implementation like Moose.



# BUGS

Please report bugs to info[at]kyledawkins.com.

# CONTRIBUTING

The github repository is at git://github.com/quile/keyvaluecoding-perl.git



# SEE ALSO

Some other stuff.

# AUTHOR

Kyle Dawkins, <info[at]kyledawkins.com>



# COPYRIGHT AND LICENSE

(c) Copyright 2001-2012 by Kyle Dawkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.