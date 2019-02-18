# NAME

MooseX::SingleArg - No-fuss instantiation of Moose objects using a single argument.

# SYNOPSIS

    package Person;
    use Moose;
    
    use MooseX::SingleArg;
    
    single_arg 'name';
    
    has name => ( is=>'ro', isa=>'Str' );
    
    my $john = Person->new( 'John Doe' );
    print $john->name();

# DESCRIPTION

This module allows Moose instances to be constructed with a single argument.
Your class or role must use this module and then use the single\_arg sugar to
declare which attribute will be assigned the single argument value.

If the class is constructed using the typical argument list name/value pairs,
or with a hashref, then things work as is usual.  But, if the arguments are a
single non-hashref value then that argument will be assigned to whatever
attribute you have declared.

The reason for this module's existence is that when people want this feature
they usually find [Moose::Cookbook::Basics::Person\_BUILDARGSAndBUILD](https://metacpan.org/pod/Moose::Cookbook::Basics::Person_BUILDARGSAndBUILD) which
asks that something like the following be written:

    around BUILDARGS => sub {
        my $orig = shift;
        my $class = shift;
        
        if ( @_ == 1 && ! ref $_[0] ) {
            return $class->$orig(ssn => $_[0]);
        }
        else {
            return $class->$orig(@_);
        }
    };

The above is complex boilerplate for a simple feature.  This module aims to make
it simple and fool-proof to support single-argument Moose object construction.

# INIT\_ARG BEHAVIOR

If setting a custom init\_arg for an attribute which you will be assigning as the
single\_arg then use the init\_arg value, rather than the attribute key, for it.
For example:

    single_arg 'moniker';
    has name => ( is=>'ro', isa=>'Str', init_arg=>'moniker' );

# FORCING SINGLE ARG PROCESSING

An optional force parameter may be specified:

    single_arg name => (
        force => 1,
    );

This causes constructor argument processing to only work in single-argument mode.  If
more than one argument is passed then an error will be thrown.  The benefit of forcing
single argument processing is that hashrefs may now be used as the value of the single
argument when force is on.

# SEE ALSO

[MooseX::OneArgNew](https://metacpan.org/pod/MooseX::OneArgNew) solves the same problem that this module solves.  I considered using OneArgNew
for my own needs, but found it oddly cumbersome and confusing.  Maybe that's just me, but I hope that
this module's design is much simpler to comprehend and more natural to use.

# AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

# CONTRIBUTORS

- Xavier Guimard <x.guimard@free.fr>
- Mohammad S Anwar <mohammad.anwar@yahoo.com>

# LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
