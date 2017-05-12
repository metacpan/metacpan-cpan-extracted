# NAME

PDLx::DetachedObject - parent class for subclassing PDL from class frameworks

# SYNTAX

### Moo

    package MyPDL;

    use Moo;
    use PDL::Lite;

    extends 'PDLx::DetachedObject';

    has PDL => ( is => 'rw' );

### Class::Tiny

    package MyPDL;

    use Class::Tiny qw[ PDL ];

    use parent 'PDLx::DetachedObject';

### Object::Tiny

    package MyPDL;

    use Object::Tiny qw[ PDL ];

    use parent 'PDLx::DetachedObject';

### Class::Accessor

    package MyPDL;

    use parent 'Class::Accessor', 'PDLx::DetachedObject';
    __PACKAGE__->follow_best_practice;
    __PACKAGE__->mk_accessors( 'PDL' );

or with Antlers:

    package MyPDL;
    use Class::Accessor "antlers";
    use parent 'PDLx::DetachedObject';

    has PDL => ( is => 'ro' );

# DESCRIPTION

[PDL](https://metacpan.org/pod/PDL) has a [non-standard way of handling
subclasses](https://metacpan.org/pod/PDL::Objects). Because a **PDL** object is a blessed scalar,
outside of using inside-out classes as the subclass, there is no easy
means of adding extra attributes to the object.

To work around this, **PDL** will treat any hash blessed into a
subclass of PDL which has an entry with key `PDL` whose value is a
real **PDL** object as a **PDL** object.

So far, here's a [**Moo**](https://metacpan.org/pod/Moo) version of the class

    package MyPDL;

    use Moo;

    extends 'PDL';

    # don't pass any constructor arguments to PDL->new; it confuses it
    sub FOREIGNBUILDARGS {}

    has PDL => ( is => 'rw' );
    has required_attr => ( is => 'ro', required =>1 );

When **PDL** needs to instantiate an object from the subclass,
it doesn't call the subclass's constructor, rather it calls the
**initialize** class method, which is expected to return a hash,
blessed into the subclass, containing the `PDL` key as well as any
other attributes.

    sub initialize {
      my $class = shift;
      bless { PDL => PDL->null }, $class;
    }

The **initialize** method is invoked in a variety of places.  For
instance, it's called in **PDL::new**, which due to **Moo**'s
inheritance scheme will be called by **MyPDL**'s constructor:

    $mypdl = MyPDL->new( required_attr => 2 );

It's also called when **PDL** needs to create an object to recieve
the results of a **PDL** operation on a **MyPDL** object:

    $newpdl = $mypdl + 1;

There's one wrinkle, however.  **PDL** _must_ create an object without
any extra attributes (it cannot know which values to give them) so
**initialize()** is called with a _single_ argument, the class name.
This means that `$newpdl` will be an _incomplete_ **MyPDL** object,
i.e.  `required_attr` is uninitiailzed. This can _really_ confuse
polymorphic code which operates differently when handed a **PDL** or
**MyPDL** object.

One way out of this dilemma is to have **PDL** create a _normal_ piddle
instead of a **MyPDL** object.  **MyPDL** has explicitly indicated it wants to be
treated as a normal piddle in **PDL** operations (by subclassing from **PDL**) so
this doesn't break that contract.

    $newpdl = $mypdl + 1;

would result in `$newpdl` being a normal **PDL** object, not a **MyPDL**
object.

Subclassing from **PDLx::DetachedObject** effects this
behavior. **PDLx::DetachedObject** provides a wrapper constructor and
an **initialize** class method.  The constructor ensures returns a
properly subclassed hash with the `PDL` key, keeping **PDL** happy.
When **PDL** calls the **initialize** function it gets a normal **PDL**.

## Using with Class Frameworks

The ["SYNOPSIS"](#synopsis) shows how to use **PDLx::DetachedObject** with various
class frameworks.  The key differentiation between frameworks is
whether or not they will call a superclass's constructor.  **Moo**
always calls it, **Class::Tiny** calls it only if it inherits from
**Class::Tiny::Object**, and **Object::Tiny** and **Class::Accessor**
never will call the superclass' constructor.

# BUGS AND LIMITATIONS

Please report any bugs or feature requests to
`bug-pdlx-mask@rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/Public/Dist/Display.html?Name=PDLx-DetachedObject](http://rt.cpan.org/Public/Dist/Display.html?Name=PDLx-DetachedObject).

# VERSION

Version 0.01

# LICENSE AND COPYRIGHT

Copyright (c) 2016 The Smithsonian Astrophysical Observatory

PDLx::DetachedObject is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see &lt;http://www.gnu.org/licenses/>.

# AUTHOR

Diab Jerius  <djerius@cpan.org>
