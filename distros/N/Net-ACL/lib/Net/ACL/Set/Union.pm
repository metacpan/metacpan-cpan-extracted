#!/usr/bin/perl

# $Id: Union.pm,v 1.7 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::Set::Union;

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
 my $data = $data[$this->{_index}];
 croak __PACKAGE__ . "->set needs to operate on an array reference!"
	unless ref $data eq 'ARRAY';
 my %res;

 foreach my $elem ( @{$data}, @{$this->{_value}} )
  {
   $res{$elem} = 1;
  };

 $data[$this->{_index}] = [ sort keys %res ];
 return @data;
}

sub value
{
 my $this = shift;
 $this->{_value} = @_ ? shift : $this->{_value};
 return $this->{_value};
}

## POD ##

=pod

=head1 NAME

Net::ACL::Set::Union - Class updating array references doing unions

=head1 SYNOPSIS

    use Net::ACL::Set::Union;

    # Construction
    my $set = new Net::ACL::Set::Union(1,[42,45]);

    # Accessor Methods
    @data = $set->set(@data);

=head1 DESCRIPTION

This module is a list manipulator, which can replace a list with the union of
the list and another list. It is used with L<Net::ACL::Rule|Net::ACL::Rule>.

=head1 CONSTRUCTOR

=over 4

=item new() - Construct a new Net::ACL::Set::Union object

    my $set = new Net::ACL::Set::Union(1,[42,45]);

This is the constructor for Net::ACL::Set::Scalar objects.
It returns a reference to the newly created object.

It takes one argument. If the argument is an array reference with one element,
the element will be placed instead of the first argument to the set method.

If an array reference has more then one element, the second element should be
the argument number to be replaced in the set method.

Otherwise, the value will directly be used instead of the first argument of
the set method.

=back

=head1 ACCESSOR METHODS

=over 4

=item set()

This function modifies the arguments according to the arguments of the
constructor and returns them.

=back

=head1 SEE ALSO

Net::ACL::Set, Net::ACL::Rule, Net::ACL

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End Package Net::ACL::Set::Scalar ##
 
1;
