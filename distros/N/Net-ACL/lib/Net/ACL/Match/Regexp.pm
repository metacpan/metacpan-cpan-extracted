#!/usr/bin/perl

# $Id: Regexp.pm,v 1.10 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::Match::Regexp;

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
 my $pattern = $this->{_value};
 my $data = $_[$this->{_index}];
 return $data =~ /$pattern/ ? ACL_MATCH : ACL_NOMATCH;
}

## POD ##

=pod

=head1 NAME

Net::ACL::Match::Regexp - Class matching a scalar data element

=head1 SYNOPSIS

    use Net::ACL::Match::Regexp;

    # Construction
    my $match = new Net::ACL::Match::Regexp(['^65001 [0-9 ]+ 65002$', 2]);

    # Accessor Methods
    $rc = $match->match(@data); # same as: $data[1] eq 42 ? ACL_MATCH : ACL_NOMATCH;

=head1 DESCRIPTION

This module is a very simple array element testing with regular expression
utility to allow simple value matching with L<Net::ACL::Rule|Net::ACL::Rule>.

=head1 CONSTRUCTOR

    my $match = new Net::ACL::Match::Regexp(['^65001 [0-9 ]+ 65002$',2]);

This is the constructor for Net::ACL::Match::Regexp objects.
It returns a reference to the newly created object.

It takes one argument. If the argument is a array reference with one element,
the element will be used as a regular expression pattern to matched with the first
argument to the match method.

If an array reference has more then one element, the second element should be
the argument number to be matched in the match method.

Otherwise, the value it self will be used as a regular expression pattern to match the
first argument of the match method.

=head1 ACCESSOR METHODS

I<match()>

This function matches the arguments according to the arguments of the
constructor and returns either C<ACL_MATCH> or C<ACL_NOMATCH> as exported by
Net::ACL::Rule with C<:rc>.

=head1 SEE ALSO

Net::ACL::Match, Net::ACL::Rule, Net::ACL

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End Package Net::ACL::Match::Regexp ##
 
1;
