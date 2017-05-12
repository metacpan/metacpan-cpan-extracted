#!/usr/bin/perl

# $Id: Add.pm,v 1.11 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::Set::Add;

use strict;
use vars qw( $VERSION @ISA );

## Inheritance and Versioning ##

@ISA     = qw( Net::ACL::Set::Scalar );
$VERSION = '0.07';

## Module Imports ##

use Net::ACL::Set::Scalar;
use Carp;

## Public Object Methods ##

sub set
{
 my $this = shift;
 my @data = @_;
 my $ax = $data[$this->{_index}];
 # $data[$this->{_index}] += $this->{_value}; # Segfault in some ASPath stuff!
 $data[$this->{_index}] = $data[$this->{_index}] + $this->{_value};
 return @data;
}

## POD ##

=pod

=head1 NAME

Net::ACL::Set::Add - Class adding a value to a data element

=head1 SYNOPSIS

    use Net::ACL::Set::Add;

    # Construction
    my $set = new Net::ACL::Set::Add(42,1);

    # Accessor Methods
    @data = $set->set(@data); # same as: $data[1] += 42;

=head1 DESCRIPTION

This module is a very simple array element addition utility to allow
simple value addition with Net::ACL::Rule. Note that using overloading
of the "+=" operator, complex operation can be executed for objects.

=head1 CONSTRUCTOR

=over 4

=item new()

    my $set = new Net::ACL::Set::Add(42,1);

This is the constructor for Net::ACL::Set::Add objects.
It returns a reference to the newly created object.

The first argument is the argument number to set that should be modified.
The second argument are the value added the the element.

=back

=head1 ACCESSOR METHODS

=over 4

=item set()

This function modifies the arguments according to the arguments of the
constructor and returns them.

=back

=head1 SEE ALSO

Net::ACL::Set, Net::ACL::Set::Scalar, Net::ACL

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End Package Net::ACL::Set::Add ##
 
1;
