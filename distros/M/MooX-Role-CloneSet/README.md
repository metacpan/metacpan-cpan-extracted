# NAME

MooX::Role::CloneSet - create updated copies of immutable objects

# SYNOPSIS

    package Someone;

    use Moo;
    with 'MooX::Role::CloneSet';

    has name => (
        is => 'ro',
    );

    has race => (
        is => 'ro',
    );

    package main;

    my $first = Someone->new(name => 'Drizzt', race => 'drow');

    my $hybrid = $first->cset(race => 'dwarf');

    my $final = $weird->cset(name => 'Catti-brie', race => 'human');

# DESCRIPTION

`MooX::Role::CloneSet` is a role for immutable objects, providing an easy
way to create a new object with some modified properties.  It provides
the `cset()` method that creates a new object with the specified changes,
shallowly copying all the rest of the original object's properties.

# METHODS

- cset(field => value, ...)

    Shallowly clone the object, making the specified changes to its attributes.

    Note that this method obtains the names and values of the current attributes
    by dereferencing the object as a hash reference; since Moo does not provide
    metaclasses by default, it cannot really get to them in any other way.
    This will not work for parameters that declare an `init_arg`; see
    `MooX::Role::CloneSet::BuildArgs` for an alternative if using truly
    immutable objects.

# LICENSE

SPDX-FileCopyrightText: Peter Pentchev <roam@ringlet.net>
SPDX-License-Identifier: Artistic-2.0

# AUTHOR

Peter Pentchev <roam@ringlet.net>
