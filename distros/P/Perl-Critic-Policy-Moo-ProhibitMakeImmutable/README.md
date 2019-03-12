# NAME

Perl::Critic::Policy::Moo::ProhibitMakeImmutable - Makes sure that Moo classes
do not contain calls to make\_immutable. (DEPRECATED)

# DESCRIPTION

When migrating from [Moose](https://metacpan.org/pod/Moose) to [Moo](https://metacpan.org/pod/Moo) it can be a common issue to accidentally
leave in:

    __PACKAGE__->meta->make_immutable;

This policy complains if this exists in a Moo class as it triggers Moose to be
loaded and metaclass created, which defeats some of the benefits you get using
Moo instead of Moose.

# DEPRECATED

This module has lost its usefulness as [Moo](https://metacpan.org/pod/Moo)'s behavior is now clearly
documented as NOT loading Moose when `make_immutable` is called.

Read more about the ["meta" in Moo](https://metacpan.org/pod/Moo#meta) method for details of the current behavior.

# AUTHORS

    Aran Clary Deltac <bluefeet@gmail.com>
    Kivanc Yazan <kyzn@users.noreply.github.com>
    Graham TerMarsch <graham@howlingfrog.com>

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
