# NAME

MooX::PDL::Role::Proxy - treat a container of ndarrays (piddles) as if it were an ndarray (piddle)

# VERSION

version 0.08

# SYNOPSIS

    package My::Class;

    use Moo;
    use MooX::PDL::Role::Proxy;

    use PDL;

    has p1 => (
        is      => 'rw',
        default => sub { sequence( 10 ) },
        ndarray  => 1
    );

    has p2 => (
        is      => 'rw',
        default => sub { sequence( 10 ) + 1 },
        ndarray  => 1
    );


    sub clone_with_ndarrays {
        my ( $self, %ndarrays ) = @_;

        $self->new->_set_attr( %ndarrays );
    }


    my $obj = My::Class->new;

    # clone $obj and filter ndarrays.
    my $new = $obj->where( $obj->p1 > 5 );

# DESCRIPTION

**MooX::PDL::Role::Proxy** is a [Moo::Role](https://metacpan.org/pod/Moo%3A%3ARole) which turns its
consumer into a proxy object for some of its attributes, which are
assumed to be **PDL** objects (or other proxy objects). A subset of
**PDL** methods applied to the proxy object are applied to the selected
attributes. (See [PDL::QuckStart](https://metacpan.org/pod/PDL%3A%3AQuckStart) for more information on **PDL** and
its objects (ndarrays)).

As an example, consider an object representing a set of detected
events (think physics, not computing), which contains metadata
describing the events as well as ndarrays representing event position,
energy, and arrival time.  The structure might look like this:

    {
        metadata => \%metadata,
        time   => $time,         # ndarray
        x      => $x,            # ndarray
        y      => $y,            # ndarray
        energy => $energy        # ndarray
    }

To filter the events on energy would traditionally be performed
explicitly on each element in the structure, e.g.

    my $mask = which( $obj->{energy} > 20 );

    my $copy = {};
    $copy->{time}   = $obj->{time}->where( $mask );
    $copy->{x}      = $obj->{x}->where( $mask );
    $copy->{y}      = $obj->{y}->where( $mask );
    $copy->{energy} = $obj->{energy}->where( $mask );

Or, more succinctly,

    $new->{$_} = $obj->{$_}->where( $mask ) for qw( time x y energy );

With **MooX::PDL::Role::Proxy** this turns into

    my $copy = $obj->where( $mask );

Or, if the results should be stored in the same object,

    $obj->inplace->where( $mask );

## Usage and Class requirements

Each attribute to be operated on by the common `PDL`-like
operators should be given a `ndarray` option, e.g.

    has p1 => (
        is      => 'rw',
        default => sub { sequence( 10 ) },
        ndarray  => 1,
    );

(Treat the option value as an identifier for the group of ndarrays
which should be operated on, rather than as a boolean).

## Results of Operations

The results of operations may either be stored ["In Place"](#in-place) or
returned in ["Cloned Objects"](#cloned-objects).  By default, operations return cloned
objects.  Note that ndarrays in cloned objects are not necessarily
independent of the original ndarrays, unless the operation included a
`copy` or a `sever`.

### In Place

Use one of the following methods, ["inplace"](#inplace), ["inplace\_store"](#inplace_store), ["inplace\_set"](#inplace_set).
to indicate that the next in-place aware operation should be performed in-place.
After the operation is completed, the in-place flag will be reset.

To support inplace operations, attributes tagged with the `ndarray`
option must have write accessors.  They may be public or private.

### Cloned Objects

The class must provide a a clone method.  If cloning an object
requires extra arguments, use ["\_set\_clone\_args"](#_set_clone_args) and
["\_clear\_clone\_args"](#_clear_clone_args) to set or reset the arguments.

If the class provides the [\_clone\_with\_ndarrays](https://metacpan.org/pod/_clone_with_ndarrays) method, then it will be called as

    $object->_clone_with_ndarrays( \%ndarrays, ?$arg);

where `$arg` will only be passed if ["\_set\_clone\_args"](#_set_clone_args) was called.

For backwards compatibility, the [clone\_with\_piddles](https://metacpan.org/pod/clone_with_piddles) method is supported, but
it is not possible to pass in extra arguments. It will be called as

    $object->clone_with_piddles ( %ndarrays );

## Nested Proxy Objects

A class with the applied role should respond equivalently to a true
ndarray when the supported methods are called on it (it's a bug
otherwise).  Thus, it is possible for a proxy object to contain
another, and as long as the contained object has the `ndarray`
attribute set, the supported method will be applied to the
contained object appropriately.

# METHODS

## \_ndarrays

    @ndarray_names = $obj->_ndarrays;

This returns a list of the names of the object's attributes with a
`ndarray` (or for backwards compatibility, `piddle` ) tag set.  The
list is lazily created by the `_build__ndarrays` method, which can be
modified or overridden if required. The default action is to find all
tagged attributes with tags `ndarray` or `piddle`.

## \_clear\_ndarrays

Clear the list of attributes which have been tagged as ndarrays.  The
list will be reset to the defaults when `_ndarrays` is next invoked.

## \_apply\_to\_tagged\_attrs

    $obj->_apply_to_tagged_attrs( \&sub );

Execute the passed subroutine on all of the attributes tagged with
`ndarray` (or `piddle`). The subroutine will be invoked as

    sub->( $attribute, $inplace )

where `$inplace` will be true if the operation is to take place inplace.

The subroutine should return the ndarray to be stored.

Returns `$obj` if applied in-place, or a new object if not.

## inplace

    $obj->inplace( ?$how )

Indicate that the next _inplace aware_ operation should be done inplace.

An optional argument indicating how the ndarrays should be updated may be
passed (see ["set\_inplace"](#set_inplace) for more information).  This API differs from
from the [inplace](https://metacpan.org/pod/PDL%3A%3ACore#inplace) method.

It defaults to using the attributes' accessors to store the results,
which will cause triggers, etc. to be called.

Returns `$obj`.
See also ["inplace\_direct"](#inplace_direct) and ["inplace\_accessor"](#inplace_accessor).

## inplace\_store

    $obj->inplace_store

Indicate that the next _inplace aware_ operation should be done
inplace.  NDarrays are changed inplace via the `.=` operator, avoiding
any side-effects caused by using the attributes' accessors.

It is equivalent to calling

    $obj->set_inplace( MooX::PDL::Role::Proxy::INPLACE_STORE );

Returns `$obj`.
See also ["inplace"](#inplace) and ["inplace\_accessor"](#inplace_accessor).

## inplace\_set

    $obj->inplace_set

Indicate that the next _inplace aware_ operation should be done inplace.
The object level attribute accessors will be used to store the results (which
may be the same ndarray).  This will cause [Moo](https://metacpan.org/pod/Moo) triggers, etc to be
called.

It is equivalent to calling

    $obj->set_inplace( MooX::PDL::Role::Proxy::INPLACE_SET );

Returns `$obj`.
See also ["inplace\_store"](#inplace_store) and ["inplace"](#inplace).

## set\_inplace

    $obj->set_inplace( $value );

Change the value of the inplace flag.  Accepted values are

- MooX::PDL::Role::Proxy::INPLACE\_SET

    Use the object level attribute accessors to store the results (which
    may be the same ndarray).  This will cause [Moo](https://metacpan.org/pod/Moo) triggers, etc to be
    called.

- MooX::PDL::Role::Proxy::INPLACE\_STORE

    Store the results directly in the existing ndarray using the `.=` operator.

## is\_inplace

    $bool = $obj->is_inplace;

Test if the next _inplace aware_ operation should  be done inplace

## copy

    $new = $obj->copy;

Create a copy of the object and its ndarrays.  If the `inplace` flag
is set, it returns `$obj` otherwise it is exactly equivalent to

    $obj->clone_with_ndarrays( map { $_ => $obj->$_->copy } @{ $obj->_ndarrays } );

## sever

    $obj = $obj->sever;

Call ["sever" in PDL::Core](https://metacpan.org/pod/PDL%3A%3ACore#sever) on tagged attributes.  This is done inplace.
Returns `$obj`.

## index

    $new = $obj->index( NDARRAY );

Call ["index" in PDL::Slices](https://metacpan.org/pod/PDL%3A%3ASlices#index) on tagged attributes.  This is inplace aware.
Returns `$obj` if applied in-place, or a new object if not.

## at

    $obj = $obj->at( @indices );

Returns a simple object containing the results of running
["index" in PDL::Core](https://metacpan.org/pod/PDL%3A%3ACore#index) on tagged attributes.  The object's attributes are
named after the tagged attributes.

## where

    $obj = $obj->where( $mask );

Apply ["where" in PDL::Primitive](https://metacpan.org/pod/PDL%3A%3APrimitive#where) to the tagged attributes.  It is in-place aware.
Returns `$obj` if applied in-place, or a new object if not.

## \_set\_clone\_args

    $obj->_set_clone_args( $args );

Pass the given value to the `_clone_with_args_ndarrays` method when
an object must be implicitly cloned.

## \_clear\_clone\_args

    $obj->_clear_clone_args;

Clear out any value set by [\_set\_clone\_args](https://metacpan.org/pod/_set_clone_args).

## \_set\_attr

    $obj->_set_attr( %attr )

Set the object's attributes to the values in the `%attr` hash.

Returns `$obj`.

## qsort

    $obj->qsort;

Sort the ndarrays.  This requires that the object has a `qsorti` method, which should
return an ndarray index of the elements in ascending order.

For example, to designate the `radius` attribute as that which should be sorted
on by qsort, include the `handles` option when declaring it:

    has radius => (
        is      => 'ro',
        ndarray  => 1,
        isa     => Piddle1D,
        handles => ['qsorti'],
    );

It is in-place aware. Returns `$obj` if applied in-place, or a new object if not.

## qsort\_on

    $obj->sort_on( $ndarray );

Sort on the specified `$ndarray`.

It is in-place aware.
Returns `$obj` if applied in-place, or a new object if not.

## clip\_on

    $obj->clip_on( $ndarray, $min, $max );

Clip on the specified `$ndarray`, removing elements which are outside
the bounds of \[`$min`, `$max`).  Either bound may be `undef` to indicate
it should be ignore.

It is in-place aware.

Returns `$obj` if applied in-place, or a new object if not.

## slice

    $obj->slice( $slice );

Slice.  See ["slice" in PDL::Slices](https://metacpan.org/pod/PDL%3A%3ASlices#slice) for more information.

It is in-place aware.
Returns `$obj` if applied in-place, or a new object if not.

# LIMITATIONS

There are significant limits to this encapsulation.

- The ndarrays operated on must be similar enough in structure so that
the ganged operations make sense (and are valid!).
- There is (currently) no way to indicate that there are different sets
of ndarrays contained within the object.
- The object must be able to be cloned relatively easily, so that
non-inplace operations can create copies of the original object.

# SUPPORT

## Bugs

Please report any bugs or feature requests to bug-moox-pdl-role-proxy@rt.cpan.org  or through the web interface at: [https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-PDL-Role-Proxy](https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-PDL-Role-Proxy)

## Source

Source is available at

    https://codeberg.com/djerius/moox-pdl-role-proxy

and may be cloned from

    https://codeberg.com/djerius/moox-pdl-role-proxy.git

# AUTHOR

Diab Jerius <djerius@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007
