# NAME

MooseX::Role::JSONObject - create/store an object in a JSON-like hash

# SYNOPSIS

    package foo;
    
    use Moose;
    with 'MooseX::Role::JSONObject';
    
    ...
    
    my $obj = foo->new(...);
    my $data = $obj->to_json();
    ...
    my $newobj = foo->from_json($data);

# DESCRIPTION

The `MooseX::Role::JSONObject` role provides two methods, `to_json()`
and `from_json()`, for storing and retrieving a Moose object's attributes
and, if they are Moose objects themselves, their attributes recursively.
This is mainly useful in two cases: creating an object and all of its
attributes from a hash parsed from a JSON string or storing an object and
all its attributes as a hash to be written to a JSON string.

# METHODS

The `MooseX::Role::JSONObject` role provides two methods:

- `to_json()`

    The `to_json()` method takes no parameters and returns a hash reference
    containing the object's data.

- `from_json($data)`

    The `from_json()` class method creates a new object with the specified
    values for its attributes.  If any of its attributes are Moose objects,
    `from_json()` will create new instances for those recursively and
    populate them from the data.

    Currently the `from_json()` method always creates a new object; even
    though it may be invoked on an already existing object instance, it will
    not modify the instance's attributes, but return a new one instead.

# SEE ALSO

[MooseX::Role::JSONObject::Meta::Trait](https://metacpan.org/pod/MooseX::Role::JSONObject::Meta::Trait)

# LICENSE

Copyright (C) 2015  Peter Pentchev <roam@ringlet.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Peter Pentchev <roam@ringlet.net>
