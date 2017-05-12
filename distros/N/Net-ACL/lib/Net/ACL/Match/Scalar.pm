#!/usr/bin/perl

# $Id: Scalar.pm,v 1.11 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::Match::Scalar;

use strict;
use vars qw( $VERSION @ISA );

## Inheritance and Versioning ##

@ISA     = qw( Net::ACL::Match );
$VERSION = '0.07';

## Module Imports ##

use Net::ACL::Match;
use Net::ACL::Rule qw( :rc );
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

sub match
{
 my $this = shift;
 return $_[$this->{_index}] eq $this->{_value} ? ACL_MATCH : ACL_NOMATCH;
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

Net::ACL::Match::Scalar - Class matching a scalar data element

=head1 SYNOPSIS

    use Net::ACL::Match::Scalar;

    # Construction
    my $match = new Net::ACL::Match::Scalar([42,1]);

    # Accessor Methods
    $rc = $match->match(@data); # same as: $data[1] eq 42 ? ACL_MATCH : ACL_NOMATCH;

=head1 DESCRIPTION

This module is a very simple array element testing utility to allow
simple value matching with L<Net::ACL::Rule|Net::ACL::Rule>.

=head1 CONSTRUCTOR

=over 4

=item new() - create a new Net::ACL::Match::Scalar object 

    my $match = new Net::ACL::Match::Scalar(42,1);

This is the constructor for Net::ACL::Match::Scalar objects.
It returns a reference to the newly created object.

It takes one argument. If the argument is a array reference with one element,
the element will be matched with the first argument to the match method.

If an array reference has more then one element, the second element should be
the argument number to be matched in the match method.

Otherwise, the value it self will be matched with the first argument of
the match method.

=back

=head1 ACCESSOR METHODS

=over 4

=item match()

This function matches the arguments according to the arguments of the
constructor and returns either C<ACL_MATCH> or C<ACL_NOMATCH> as exported by
Net::ACL::Rule with C<:rc>.

=back

=head1 SEE ALSO

Net::ACL::Match, Net::ACL::Rule, Net::ACL, Net::ACL::Set::Scalar

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End Package Net::ACL::Match::Scalar ##
 
1;
