# NAME

PDLx::Mask - Mask multiple piddles with automatic two way feedback

# VERSION

version 0.06

# SYNOPSIS

    use 5.10.0;
    use PDLx::Mask;
    use PDLx::MaskedData;

    $pdl = sequence( 9 );

    $mask = PDLx::Mask->new( $pdl->ones );
    say $mask;    # [1 1 1 1 1 1 1 1 1]

    $data1 = PDLx::MaskedData->new( $pdl, $mask );
    say $data1;    # [0 1 2 3 4 5 6 7 8]

    $data2 = PDLx::MaskedData->new( $pdl + 1, $mask );
    say $data2;    # [1 2 3 4 5 6 7 8 9]

    # update the mask
    $mask->set( 3, 0 );
    say $mask;     # [1 1 1 0 1 1 1 1 1]

    # and see it propagate
    say $data1;    # [0 1 2 0 4 5 6 7 8]
    say $data2;    # [1 2 3 0 5 6 7 8 9]

    # use bad values for $data1
    $data1->badflag(1);
    # notice that the invalid element is now bad
    say $data1;    # [0 1 2 BAD 4 5 6 7 8]

    # push invalid values upstream to the shared mask
    $data1->upstream_mask(1);
    $data1->setbadat(0);
    say $data1;    # [BAD 1 2 BAD 4 5 6 7 8]

    # see the mask change
    say $mask;     # [0 1 1 0 1 1 1 1 1]

    # and see the other piddle change
    say $data2;    # [0 2 3 0 5 6 7 8 9]

# DESCRIPTION

Typically [PDL](https://metacpan.org/pod/PDL) uses [bad values](https://metacpan.org/pod/PDL%3A%3ABad) to mark elements in a piddle which
contain invalid data.  When multiple piddles should have the same elements
marked as invalid, a separate _mask_ piddle (whose values are true for valid data
and false otherwise) is often used.

**PDLx::Mask** in concert with [PDLx::MaskedData](https://metacpan.org/pod/PDLx%3A%3AMaskedData) simplifies the management of
multiple piddles sharing the same mask.  **PDLx::Mask** is the shared mask,
and **PDLx::MaskedData** is a specialized piddle which will dynamically respond
to changes in the mask, so that they are always up-to-date.

Additionally, invalid elements in the data piddles may automatically
be added to the shared mask, so that there is a consistent view of
valid elements across all piddles.

## Details

**PDLx::Mask** is a subclass of **PDL** which manages a mask across on
or more piddles.  It can be used directly as a piddle, but be careful
not to change its contents inadvertently. _It should only be
manipulated via the provided methods or overloaded operators._

It maintains two views of the mask:

1. the original _base_ mask; and
2. the _effective_ mask, which is the base mask combined with additional
invalid elements from the data piddles.

The [**subscribe**](#subscribe) method is used to register callbacks to be invoked
when the mask has been changed. Multiple subscriptions are allowed; each
can register two callbacks:

- A subroutine invoked when the mask has changed.  It is passed a piddle
containing the mask.  It should not alter it.
- A subroutine which will return a data mask.  If the data mask changes,
the mask's [**update**](#update) method _must_ be called.

# INTERNALS

# INTERFACE

## Methods specific to **PDLx::Mask**

### new

    $mask = PDLx::Mask->new( $base_mask );
    # or
    $mask = PDLx::Mask->new( base => $base_mask );

Create a mask using the passed mask as the base mask.  It does not
copy the passed piddle.

### base

    $base = $mask->base;

This returns the _base_ mask.
**Don't alter the returned piddle!**

### mask

    $pdl = $mask->mask;
    $pdl = $mask->mask( $new_mask );

Return the _effective_ mask as a plain piddle.
**Don't alter the returned piddle!**

If passed a piddle, it is copied to the _base_ mask and the
[**update**](#update) method is called.

Note that the `$mask` object can also be used directly without
calling this method.

### nvalid

    $nvalid_elements = $mask->nvalid;

The number of valid elements in the _effective_ mask.  This is lazily evaluated
and cached.

### subscribe

    $token = $mask->subscribe( apply_mask => $code_ref, %options );

Register the passed subroutines to be called when the _effective_
mask is changed.  The returned token may be used to unsubscribe the
callbacks using [**unsubscribe**](#unsubscribe).

The following options are available:

- `apply_mask` => _code reference_

    This subroutine should expect a single argument (a mask piddle) and
    apply it.  It should _not_ alter the mask piddle.  It is optional.

    This callback will be invoked _no_ arguments if the mask has
    been directed to unsubscribe the callbacks. See ["unsubscribe"](#unsubscribe)

- `data_mask` => _code reference_

    This subroutine should return a piddle which encodes the intrinsic
    valid elements of the object's data.  It is optional.

    The mask object does not monitor this piddle for changes.  If the data
    mask changes, the mask's [**update**](#update) method _must_ be
    called.

- token => _scalar_

    Instead of creating a new subscription, update the entry with the
    given token, which was returned by a previous invocation of
    [**subscribe**](#subscribe).

### is\_subscriber

    $bool = $mask->is_subscriber( $token );

Returns true if the passed token refers to an active subscriber.

### unsubscribe

    $mask->unsubscribe( $token );

Unsubscribe the callbacks with the given token (returned by [**subscribe**](#subscribe)).

If the callbacks for `$token` include the `apply_mask` callback, it
will be invoked with no arguments, indicating that it is being
unsubscribed. At that time `$mask->is_subscriber($token)` will
return _false_.

### update

    $mask->update;

This performs the following:

1. subscribers with [`data_mask`](#data_mask) callbacks are queried for their masks;
2. the _effective_ mask is constructed from the _base_ mask and the data masks; and
3. subscribers' [`apply_mask`](#apply_mask) callbacks are invoked
with the _effective_ mask.

## Overridden methods

### `copy`

Returns a copy of the _effective_ mask as an ordinary piddle.

### `inplace`

This is a fatal operation.

### `set_inplace()`

This is a fatal operation if the passed value is non-zero.

### set

    $mask->set( $pos, $value);

This updates the _base_ mask at position `$pos` to `$value` and
calls the [**update**](#update) method.

## Overloaded Operators

Use of assignment operators (but _not_ the underlying **PDL** methods or subroutines) other than the following
_should_ be fatal.

### `|=` `&=` `^=` `.=`

These operators may be used to update the _base_ mask.  The
_effective_ mask will automatically be updated.

# EXAMPLES

## Secondary Masks

Sometimes the primary mask should incorporate a secondary mask that's
not associated with a data set. Here's how to do that:

    $pmask = PDLx::Mask->new( pdl( byte, 1, 1, 1 ) );
    $smask = PDLx::MaskedData->new( base => pdl( byte, 0, 1, 0 ),
                                    mask => $pmask,
                                    apply_mask => 0,
                                    data_mask => 1
                                  );

The key difference between this and an ordinary dependency on a data
mask, is that by turning off `apply_mask`, changes in the primary
mask won't be replicated in the secondary.

    say $smask;       # [ 0 1 0 ]
    say $pmask->base; # [ 1 1 1 ]
    say $pmask;       # [ 0 1 0 ]

    $smask->set( 0, 1 );
    say $smask;       #  [ 1 1 0 ]
    say $pmask->base; #  [ 1 1 1 ]
    say $pmask;       #  [ 1 1 0 ]

    $pmask->set( 0, 0 );
    say $smask;       #  [ 1 1 0 ]
    say $pmask->base; #  [ 0 1 1 ]
    say $pmask;       #  [ 0 1 0 ]

## Intermittent Secondary Masks

Building upon the previous example, let's say the secondary mask is
used intermittently.  For example

    $pmask = PDLx::Mask->new( [ 1, 1, 1 ] );

    $smask = PDLx::MaskedData->new( base => [ 0, 1, 0 ],
                                    mask => $pmask,
                                    apply_mask => 0,
                                    data_mask => 1
                                  );

    $data = PDLx::MaskedData->new( [ 33, 22, 44 ], $pmask );

    say $data         #  [ 0, 22, 0 ]

    # now want to ignore secondary mask
    $smask->unsubscribe;

    say $data         #  [ 33, 22, 44 ]

    # and now stop ignoring it
    $smask->subscribe;
    say $data         #  [ 0, 22, 0 ]

# SUPPORT

## Bugs

Please report any bugs or feature requests to bug-pdlx-mask@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=PDLx-Mask

## Source

Source is available at

    https://gitlab.com/djerius/pdlx-mask

and may be cloned from

    https://gitlab.com/djerius/pdlx-mask.git

# AUTHOR

Diab Jerius <djerius@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007
