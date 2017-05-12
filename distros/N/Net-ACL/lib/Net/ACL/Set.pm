#!/usr/bin/perl

# $Id: Set.pm,v 1.11 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::Set;

use strict;
use Exporter;
use vars qw( $VERSION @ISA );

## Inheritance and Versioning ##

@ISA     = qw( Exporter );
$VERSION = '0.07';

## Module Imports ##

use Carp;

## Public Class Methods ##

sub new
{
 my $proto = shift;
 my $class = ref $proto || $proto;
 croak 'Cannot construct object of abstract class Net::ACL::Set'
	if $class eq 'Net::ACL::Set';
}

## Public Object Methods ##

sub set
{
 my $this = shift;
 my $class = ref $this || $this;
 croak 'Net::ACL::Set objects cannot set!'
	if $class eq 'Net::ACL::Set';

 croak "$class should reimplement the set method inhireted from Net::ACL::Set";
}

sub index
{
 my $this = shift;
 $this->{_index} = @_ ? shift : $this->{_index};
 return $this->{_index};
}

## POD ##

=pod

=head1 NAME

Net::ACL::Set - Abstract parent class of Set-classes

=head1 SYNOPSIS

    package Net::ACL::SetMyPackage;

    use Net::ACL::Set;
    @ISA     = qw( Net::ACL::Set );

    sub new { ... };
    sub set { ... };


    package main;

    # Construction
    my $set = new Net::ACL::SetMyPackage($args);

    # Accessor Methods
    @data = $set->set(@data);

=head1 DESCRIPTION

This is an abstract parent class for all Net::ACL::Set*
classes. It is used by the Net::ACL::Rule object.

It only has a constructor new() and a method set(). Both should be
replaced in any ancestor object.

=head1 CONSTRUCTOR

=over 4

=item 4 new() - Constructor of Net::ACL::Set* objects

    my $set = new Net::ACL::SetMyPackage($args);

This is the constructor for Net::ACL::Set::* objects.
It returns a reference to the newly created object.
It takes one argument, which should describe what to set.

=back

=head1 ACCESSOR METHODS

=over 4

=item set()

This function should modify the data given as arguments (one or more) with
the data passed to the constructor and return the modified data.

=back

=head1 SEE ALSO

Net::ACL::Rule, Net::ACL,
Net::ACL::Set::Scalar, Net::ACL::Set::Union, Net::ACL::Set::Add

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End Package Net::ACL::Set ##
 
1;
