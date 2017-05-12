# NAME

MooseX::SemiAffordanceAccessor - Name your accessors foo() and set\_foo()

# VERSION

version 0.10

# SYNOPSIS

    use Moose;
    use MooseX::SemiAffordanceAccessor;

    # make some attributes

# DESCRIPTION

This module does not provide any methods. Simply loading it changes
the default naming policy for the loading class so that accessors are
separated into get and set methods. The get methods have the same name
as the accessor, while set methods are prefixed with "set\_".

If you define an attribute with a leading underscore, then the set
method will start with "\_set\_".

If you explicitly set a "reader" or "writer" name when creating an
attribute, then that attribute's naming scheme is left unchanged.

The name "semi-affordance" comes from David Wheeler's Class::Meta
module.

# ACCESSORS IN ROLES

Prior to version 1.9900 of [Moose](https://metacpan.org/pod/Moose), attributes added to a class ended up with
that class's attribute traits. That means that if your class used
`MooseX::SemiAffordanceAccessor`, any attributes provided by roles you
consumed had the semi-affordance style of accessor.

As of Moose 1.9900, that is no longer the case. Attributes provided by roles
no longer acquire the consuming class's attribute traits. However, with Moose
1.9900+, you can now use `MooseX::SemiAffordanceAccessor` directly in
roles. Attributes defined by that role will have semi-affordance style
accessors, regardless of what attribute traits the consuming class has.

# BUGS

Please report any bugs or feature requests to
`bug-moosex-semiaffordanceaccessor@rt.cpan.org`, or through
the web interface at [http://rt.cpan.org](http://rt.cpan.org).  I will be notified, and
then you'll automatically be notified of progress on your bug as I
make changes.

# AUTHOR

Dave Rolsky <autarch@urth.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
