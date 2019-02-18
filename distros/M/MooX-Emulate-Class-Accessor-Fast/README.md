# NAME

MooX::Emulate::Class::Accessor::Fast - Emulate Class::Accessor::Fast behavior using Moo attributes.

# SYNOPSYS

    package MyClass;
    use Moo;
    
    with 'MooX::Emulate::Class::Accessor::Fast';
    
    # Fields with readers and writers:
    __PACKAGE__->mk_accessors(qw/field1 field2/);
    
    # Fields with readers only:
    __PACKAGE__->mk_ro_accessors(qw/field3 field4/);
    
    # Fields with writers only:
    __PACKAGE__->mk_wo_accessors(qw/field5 field6/);

# DESCRIPTION

This module attempts to emulate the behavior of [Class::Accessor::Fast](https://metacpan.org/pod/Class::Accessor::Fast) as
accurately as possible using the Moo attribute system. The public API of
Class::Accessor::Fast is wholly supported, but the private methods are not.
If you are only using the public methods (as you should) migration should be a
matter of switching your `use base` line to a `with` line.

This module is a straight fork-and-port of [MooseX::Emulate::Class::Accessor::Fast](https://metacpan.org/pod/MooseX::Emulate::Class::Accessor::Fast)
version `0.00903` for [Moo](https://metacpan.org/pod/Moo).  All tests from the original Moose module pass or
were, as little as possible, modified to pass.  Much of the documentation, code
concepts, and tests are just straight copied from the original module.  The core
functionality, though, had to be a complete rewrite for Moo.

While we have attempted to emulate the behavior of Class::Accessor::Fast as closely
as possible bugs may still be lurking in edge-cases.

# BEHAVIOR

Simple documentation is provided here for your convenience, but for more thorough
documentation please see [Class::Accessor::Fast](https://metacpan.org/pod/Class::Accessor::Fast) and [Class::Accessor](https://metacpan.org/pod/Class::Accessor).

# METHODS

## mk\_accessors

    __PACKAGE__->mk_accessors( @field_names );

See ["mk\_accessors" in Class::Accessor](https://metacpan.org/pod/Class::Accessor#mk_accessors).

## mk\_ro\_accessors

    __PACKAGE__->mk_ro_accessors( @field_names );

See ["mk\_ro\_accessors" in Class::Accessor](https://metacpan.org/pod/Class::Accessor#mk_ro_accessors).

## mk\_wo\_accessors

    __PACKAGE__->mk_wo_accessors( @field_names );

See ["mk\_wo\_accessors" in Class::Accessor](https://metacpan.org/pod/Class::Accessor#mk_wo_accessors).

## follow\_best\_practice

    __PACKAGE__->follow_best_practice();

See ["follow\_best\_practice" in Class::Accessor](https://metacpan.org/pod/Class::Accessor#follow_best_practice).

## mutator\_name\_for

    sub mutator_name_for { 'change_' . $_[1] }

See ["MAKING ACCESSORS" in Class::Accessor](https://metacpan.org/pod/Class::Accessor#MAKING-ACCESSORS).

## accessor\_name\_for

    sub accessor_name_for { 'retrieve_' . $_[1] }

See ["MAKING ACCESSORS" in Class::Accessor](https://metacpan.org/pod/Class::Accessor#MAKING-ACCESSORS).

## set

    $object->set( $field => $value );

See ["set" in Class::Accessor](https://metacpan.org/pod/Class::Accessor#set).

## get

    my $value = $object->get( $field );
    my @values = $object->get( $field1, $field2 );

See ["get" in Class::Accessor](https://metacpan.org/pod/Class::Accessor#get).

## make\_accessor

    my $coderef = $class->make_accessor( $field );

See ["make\_accessor" in Class::Accessor](https://metacpan.org/pod/Class::Accessor#make_accessor).

## make\_ro\_accessor

    my $coderef = $class->make_ro_accessor( $field );

See ["make\_ro\_accessor" in Class::Accessor](https://metacpan.org/pod/Class::Accessor#make_ro_accessor).

## make\_wo\_accessor

    my $coderef = $class->make_wo_accessor( $field );

See ["make\_wo\_accessor" in Class::Accessor](https://metacpan.org/pod/Class::Accessor#make_wo_accessor).

# SEE ALSO

[Moo](https://metacpan.org/pod/Moo), [Class::Accessor](https://metacpan.org/pod/Class::Accessor), [Class::Accessor::Fast](https://metacpan.org/pod/Class::Accessor::Fast),
[MooseX::Emulate::Class::Accessor::Fast](https://metacpan.org/pod/MooseX::Emulate::Class::Accessor::Fast)

# AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

Original code, tests, and documentation taken from
[MooseX::Emulate::Class::Accessor::Fast](https://metacpan.org/pod/MooseX::Emulate::Class::Accessor::Fast).  Thanks!

# CONTRIBUTORS

- Graham Knop <haarg@haarg.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
