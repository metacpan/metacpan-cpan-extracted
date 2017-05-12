#!/usr/bin/perl

# $Id: Scalar.pm,v 1.11 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::Set::Scalar;

use strict;
use vars qw( $VERSION @ISA );

## Inheritance and Versioning ##

@ISA     = qw( Net::ACL::Set );
$VERSION = '0.07';

## Module Imports ##

use Net::ACL::Set;
use Carp;

## Public Class Methods ##

sub new
{
 my $proto = shift;
 my $class = ref $proto || $proto;
 @_ = @{$_[0]} if (scalar @_ == 1) && (ref $_[0] eq 'ARRAY');

 my $this = {
        _index => shift,
        _value => shift
        };

 croak "Index need to be a number\n" unless defined $this->{_index} && $this->{_index} =~ /^[0-9]+$/;

 bless($this,$class);
 return $this;
}

## Public Object Methods ##

sub set
{
 my $this = shift;
 # $_[$this->{_index}] = $this->{_value}; # Doesn't work with constants!
 my @data = @_;
 $data[$this->{_index}] = $this->{_value};
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

Net::ACL::Set::Scalar - Class replacing a scalar data element

=head1 SYNOPSIS

    use Net::ACL::Set::Scalar;

    # Construction
    my $set = new Net::ACL::Set::Scalar(1,42);

    # Accessor Methods
    @data = $set->set(@data); # same as: $data[1] = 42;

=head1 DESCRIPTION

This module is a very simpel array ellement replacement utility to allow
simple value replacement with L<Net::ACL::Rule|Net::ACL::Rule>.

=head1 CONSTRUCTOR

=over 4

=item new()

    my $set = new Net::ACL::Set::Scalar(1,42);

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
