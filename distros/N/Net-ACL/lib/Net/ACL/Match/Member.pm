#!/usr/bin/perl

# $Id: Member.pm,v 1.5 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::Match::Member;

use strict;
use vars qw( $VERSION @ISA );

## Inheritance and Versioning ##

@ISA     = qw( Net::ACL::Match::Scalar );
$VERSION = '0.07';

## Module Imports ##

use Net::ACL::Match::Scalar;
use Net::ACL::Rule qw( :rc );
use Carp;

## Public Object Methods ##

sub match
{
 my $this = shift;
 my @data = @_;
 my $data = $data[$this->{_index}];
 croak __PACKAGE__ . "->match needs to operate on an array reference!"
        unless ref $data eq 'ARRAY';
 my %miss;
 foreach my $elem ( @{$this->{_value}} )
  {
   $miss{$elem} = 1;
  };
 foreach my $elem ( @{$data} )
  {
   delete $miss{$elem};
  };
 return scalar (keys %miss) ? ACL_NOMATCH : ACL_MATCH;
}

## POD ##

=pod

=head1 NAME

Net::ACL::Match::Member - Class matching one or more members of an array

=head1 SYNOPSIS

    use Net::ACL::Match::Member;

    # Construction
    my $match = new Net::ACL::Match::Member(1,[41,42]);

    # Accessor Methods
    $rc = $match->match(@data);

=head1 DESCRIPTION

This module is a very simple array element testing utility to allow
simple value matching with L<Net::ACL::Rule|Net::ACL::Rule>.

=head1 CONSTRUCTOR

=over 4

=item new() - create a new Net::ACL::Match::Member object 

    my $match = new Net::ACL::Match::Member(1,[41,42]);

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

Net::ACL::Match, Net::ACL::Rule, Net::ACL, Net::ACL::Set::Union

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End Package Net::ACL::Match::Member ##
 
1;
