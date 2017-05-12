#!/usr/bin/perl
# $Id$
# $Author$
# $HeadURL$
# $Date$
# $Revision$
use warnings;
use strict;
{

    package OOP::Perlish::Class::Abstract;
    use warnings;
    use strict;
    use OOP::Perlish::Class;
    use base qw(OOP::Perlish::Class);
    use Carp qw(confess);
    use Data::Dumper;

    our $VERSION = 1.0;

    ############################################################################################
    ## Do a sanity check for required interfaces in pre-validation
    ############################################################################################
    sub ____pre_validate_opts
    {
        my ($self) = @_;
        my $class = ref($self);

        my %required_interfaces;

        for my $parent_class ( $self->_all_isa() ) {
            if( bless( {}, $parent_class )->can('____OOP_PERLISH_CLASS_REQUIRED_INTERFACES') ) {
                @required_interfaces{ @{ $parent_class->____OOP_PERLISH_CLASS_REQUIRED_INTERFACES() } } = undef;
            }
        }

        my %defined_interfaces;

        for my $parent_class ( $self->_all_isa() ) {
            next if( exists( $self->____OOP_PERLISH_CLASS_ABSTRACT_CLASSES()->{$parent_class} ) );
            for my $name ( keys %required_interfaces ) {
                no strict 'refs';
                $defined_interfaces{$name} = undef if( defined( *{ '::' . $class . '::' . $name }{CODE} ) );
                use strict;
            }
        }

        if( scalar keys %required_interfaces != scalar keys %defined_interfaces ) {
            confess(   'Failed to define required interfaces: '
                     . join( ', ', grep { !exists( $defined_interfaces{$_} ) } keys %required_interfaces ) . 'in '
                     . $class );
        }

        return $self->SUPER::____pre_validate_opts();
    }

    ############################################################################################
    ## set interfaces, usually called like 'BEGIN { __PACKAGE__->_interfaces(...) }' as the
    ## first section of a derived class.
    ############################################################################################
    sub _interfaces(@)
    {
        my ( $self, %interfaces ) = @_;
        my $class = ref($self) || $self;

        $self->____OOP_PERLISH_CLASS_ABSTRACT_CLASSES()->{$class} = 1;

        for my $name ( keys %interfaces ) {
            my $type = $interfaces{$name};

            ### Symbol table manipulation; creates a method named for the $name in the package's namespace
            ### The actual method is created via closure in ____oop_perlish_class_interface_factory();
            no strict 'refs';
            *{ '::' . $class . '::' . $name } = $self->____oop_perlish_class_interface_factory( $name, $type );
            use strict;
        }

        return;
    }

    ############################################################################################
    ## return a static reference to an array of required fields for this class; must work for
    ## all derived classes
    ############################################################################################
    sub ____OOP_PERLISH_CLASS_REQUIRED_INTERFACES(@)
    {
        my ($self) = @_;
        my $class = ref($self) || $self;
        our $____OOP_PERLISH_CLASS_REQUIRED_INTERFACES;

        $____OOP_PERLISH_CLASS_REQUIRED_INTERFACES = {} unless( defined($____OOP_PERLISH_CLASS_REQUIRED_INTERFACES) );
        $____OOP_PERLISH_CLASS_REQUIRED_INTERFACES->{$class} = [] unless( exists( $____OOP_PERLISH_CLASS_REQUIRED_INTERFACES->{$class} ) );

        return $____OOP_PERLISH_CLASS_REQUIRED_INTERFACES->{$class};
    }

    ############################################################################################
    ## Place to store a registry of all abstract classes;
    ############################################################################################
    sub ____OOP_PERLISH_CLASS_ABSTRACT_CLASSES(@)
    {
        my ($self) = @_;
        our $____OOP_PERLISH_CLASS_ABSTRACT_CLASSES;

        $____OOP_PERLISH_CLASS_ABSTRACT_CLASSES = {} unless( defined($____OOP_PERLISH_CLASS_ABSTRACT_CLASSES) );

        return $____OOP_PERLISH_CLASS_ABSTRACT_CLASSES;
    }

    ############################################################################################
    ## Return a subroutine for the required interfaces
    ############################################################################################
    sub ____oop_perlish_class_interface_impl_required
    {
        my ( $self, $name ) = @_;
        my $class = ref($self) || $self;

        push( @{ $class->____OOP_PERLISH_CLASS_REQUIRED_INTERFACES() }, $name );

        return sub { confess("Interface $name is required, but was not defined"); };
    }

    ############################################################################################
    ## Return a subroutine for the optional (false) interfaces
    ############################################################################################
    sub ____oop_perlish_class_interface_impl_optional
    {
        my ( $self, $name ) = @_;
        return sub { return; };
    }

    ############################################################################################
    ## Return a subroutine for optional_true interfaces
    ############################################################################################
    sub ____oop_perlish_class_interface_impl_optional_true
    {
        my ( $self, $name ) = @_;
        return sub { return 1; };
    }

    ############################################################################################
    ## Return a subroutine for the given type
    ############################################################################################
    sub ____oop_perlish_class_interface_factory
    {
        my ( $self, $name, $type ) = @_;

        my $method = '____oop_perlish_class_interface_impl_' . lc($type);
        confess('Invalid type of interface specification') unless( $self->can($method) );
        return $self->$method($name);
    }
}
1;
__END__

=head1 NAME

OOP::Perlish::Class::Abstract

=head1 DESCRIPTION

Quickly and easily create abstract classes, which can easily be tested for via 'isa' or OOP::Perlish::Class::Accessor->implements( [ 'ClassA', 'ClassB' ] ); ('implements' is a polymorphism test, not an inheritance test, and is generally preferred)

=head1 SYNOPSIS

=over

=item Defining an abstract class

 package MyAbstractClass;
 use base qw(OOP::Perlish::Class::Abstract);

 BEGIN { 
    __PACKAGE__->_interfaces( 
        my_interface => 'required',
        my_optional_interface => 'optional',
        my_optional_but_true => 'optional_true',
    );
 };

=item Later in an implementation class:

 package MyImplementationClass;
 use base qw(MyAbstractClass);

 sub my_interface
 {
    my ($self) = @_;

    return 'foo';
 }

=item Meanwhile, in a consuming class

 package MyConsumerClass;
 use base qw(OOP::Perlish::Class);

 BEGIN {
    __PACKAGE__->_accessors(
        foo => {
            type => 'OBJECT',
            implements => [ 'MyAbstractClass' ],
        },
    );
 };

 sub quux
 {
    my ($self) = @_;

    return $self->foo()->my_interface();
 }

=item And finally, when used:

 my $foo = MyImplementationClass->new();
 my $bar = MyConsumerClass->new( foo => $foo );

 print $bar->quux() . $/;

=back

=head1 USAGE

The module provides handlers for 'required', 'optional', and 'optional_true' types of interface definitions via the following
built-in method factories:

 ############################################################################################
 ## Return a subroutine for the required interfaces
 ############################################################################################
 sub ____oop_perlish_class_interface_impl_required
 {
     my ( $self, $name ) = @_;
     my $class = ref($self) || $self;

     $self->____OOP_PERLISH_CLASS_REQUIRED_INTERFACES()->{$name} = 1;

     return sub { confess("Interface $name is required, but was not defined in $class (nor in the ancestory of $class)"); };
 }

 ############################################################################################
 ## Return a subroutine for the optional (false) interfaces
 ############################################################################################
 sub ____oop_perlish_class_interface_impl_optional
 {
     my ( $self, $name ) = @_;
     return sub { return; };
 }

 ############################################################################################
 ## Return a subroutine for optional_true interfaces
 ############################################################################################
 sub ____oop_perlish_class_interface_impl_optional_true
 {
     my ( $self, $name ) = @_;
     return sub { return 1; };
 }

if you wish to add additional handlers for an abstract class; simply define a method with the type prefixed with C<____oop_perlish_class_interface_impl_>
e.g.: 

 sub ____oop_perlish_class_interface_impl_my_type
 {
    return sub { return 'default sub for my_type'; };
 }

Which would allow you to specify in the _interfaces() call 

 BEGIN { 
    __PACKAGE__->_interfaces( 
        my_interface => 'my_type',
    );
 };

This is mostly useful for specifying default interfaces that are expected to return references to (possibly empty) hashes or arrays.

=head1 DIAGNOSTICS

 invokes confess() whenever a method is called that was 'required' but never defined. 
 invokes confess() whenever a type is specified in __PACKAGE__->_interfaces() that does not have a handler defined.
 invokes confess() whenever an object is instantiated via new and is missing a required interface definition; 

=cut
