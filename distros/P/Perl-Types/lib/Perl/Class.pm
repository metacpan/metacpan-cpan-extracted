#
# This file is part of Perl-Types
#
# This software is copyright (c) 2025 by Auto-Parallel Technologies, Inc.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
# [[[ HEADER ]]]
package Perl::Class;
use strict;
use warnings;
our $VERSION = 0.003_000;

# [[[ OO INHERITANCE ]]]
# BASE CLASS HAS NO INHERITANCE
# "The Buck Stops Here"

# [[[ CRITICS ]]]
## no critic qw(ProhibitStringyEval)  # SYSTEM DEFAULT 1: allow eval()
## no critic qw(ProhibitAutoloading RequireArgUnpacking)  # SYSTEM SPECIAL 2: allow Autoload & read-only @ARG
## no critic qw(ProhibitExcessComplexity)  # SYSTEM SPECIAL 5: allow complex code inside subroutines, must be after line 1
## no critic qw(ProhibitDeepNests)  # SYSTEM SPECIAL 7: allow deeply-nested code
## no critic qw(ProhibitNoStrict)  # SYSTEM SPECIAL 8: allow no strict
## no critic qw(RequireBriefOpen)  # SYSTEM SPECIAL 10: allow complex processing with open filehandle

# [[[ INCLUDES ]]]
use English;
use Carp;  # for croak()
use Scalar::Util 'reftype';  # to test for HASH ref when given initialization values for new() method
use Data::Dumper;

# [[[ OO PROPERTIES ]]]
# BASE CLASS HAS NO PROPERTIES

# [[[ SUBROUTINES & OO METHODS ]]]

# Perl object constructor, SHORT FORM
sub new {
    no strict;
    if ( not defined ${ $_[0] . '::properties' } ) {
        croak 'ERROR ECOOOCO00, SOURCE CODE, OO OBJECT CONSTRUCTOR: Undefined hashref $properties for class ' . $_[0] . ', croaking' . "\n";
    }
#    return bless { %{ ${ $_[0] . '::properties' } } }, $_[0];  # DOES NOT INHERIT PROPERTIES FROM PARENT CLASSES
#    return bless { %{ ${ $_[0] . '::properties' } }, %{ properties_inherited($_[0]) } }, $_[0];  # WHAT DOES THIS DO???
#    return bless { %{ properties_inherited($_[0]) } }, $_[0];  # WORKS PROPERLY, BUT DOES NOT INITIALIZE PROPERTIES
    return bless { %{ properties_inherited_initialized($_[0], $_[1]) } }, $_[0];
}


# allow properties to be initialized by passing them as hashref arg to new() method
sub properties_inherited_initialized {
#    print {*STDERR} 'in Class::properties_inherited_initialized(), top of subroutine, received $ARG[0] = ', $ARG[0], "\n";
#    print {*STDERR} 'in Class::properties_inherited_initialized(), top of subroutine, received $ARG[1] = ', Dumper($ARG[1]), "\n";

    my $properties_inherited = properties_inherited($_[0]);

    if (defined $_[1]) {
        if ((not defined reftype($_[1])) or (reftype($_[1]) ne 'HASH')) {
            croak 'ERROR ECOOOCO01, SOURCE CODE, OO OBJECT CONSTRUCTOR: Initialization values for new() method must be key-value pairs inside a hash reference, croaking';
        }
        foreach my $property_name (sort keys %{$_[1]}) {
            if (not exists $properties_inherited->{$property_name}) {
                croak 'ERROR ECOOOCO02, SOURCE CODE, OO OBJECT CONSTRUCTOR: Attempted initialization of invalid property ' . q{'} . $property_name . q{'} . ', croaking';
            }
            $properties_inherited->{$property_name} = $_[1]->{$property_name};
        }
    }

    return $properties_inherited;
}


# inherit properties from parent and grandparnt classes
sub properties_inherited {
#    print {*STDERR} 'in Class::properties_inherited(), top of subroutine, received $ARG[0] = ', $ARG[0], "\n";
    no strict;

    # always keep self class' $properties
    my $properties = { %{ ${ $ARG[0] . '::properties' } } };

    # inherit parent & (great*)grandparent class' $properties
    foreach my $parent_package_name (@{ $ARG[0] . '::ISA' }) {
#        print {*STDERR} 'in Class::properties_inherited(), top of foreach() loop, have $parent_package_name = ', $parent_package_name, "\n";

        # DEV NOTE: changed from original RPerl version, WBRASWELL 20230219
        # DEV NOTE: changed from original RPerl version, WBRASWELL 20230219
        # DEV NOTE: changed from original RPerl version, WBRASWELL 20230219
        # base class has no $properties, skip
        if ($parent_package_name eq 'Perl::Class') {
        # Perl base class & Eyapp classes have no $properties, skip
#        if (($parent_package_name eq 'Perl::Class') or
#            ($parent_package_name eq 'Parse::Eyapp::Node')) {
                next;
        }


        # recurse to get inherited $properties
        my $parent_and_grandparent_properties = properties_inherited($parent_package_name);

        # self class' $properties override inherited $properties, same as C++
        foreach my $parent_property_key (keys %{ $parent_and_grandparent_properties }) {
            if (not exists $properties->{$parent_property_key}) {
                $properties->{$parent_property_key} = $parent_and_grandparent_properties->{$parent_property_key};
            }
        }
    }
    return $properties;
}

1;
