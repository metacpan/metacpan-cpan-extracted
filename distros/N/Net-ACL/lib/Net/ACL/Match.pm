#!/usr/bin/perl

# $Id: Match.pm,v 1.13 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::Match;

use strict;
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
 croak 'Cannot construct object of abstract class Net::ACL::Match'
	if $class eq 'Net::ACL::Match';
}

## Public Object Methods ##

sub match
{
 my $this = shift;
 my $class = ref $this || $this;
 croak __PACKAGE__ . ' objects cannot match!'
	if $class eq __PACKAGE__;

 croak "$class should reimplement the match method inhireted from " . __PACKAGE__;
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

Net::ACL::Match - Abstract parent class of Match-classes

=head1 SYNOPSIS

    package Net::ACL::MatchMyPackage;

    use Net::ACL::Match;
    @ISA     = qw( Net::ACL::Match );

    sub new { ... };
    sub match { ... };


    package main;

    # Construction
    my $match = new Net::ACL::MatchMyPackage($args);

    # Accessor Methods
    $rc = $match->match(@data);
    $index = $match->index($index);

=head1 DESCRIPTION

This is an abstract parent class for all Net::ACL::Match*
classes. It is used by the Net::ACL::Rule object.

It only has a constructor new() and two methods match() and index().
Both new and match should be replaced in any ancestor object.

=head1 CONSTRUCTOR

=over 4

=item new() - create a new Net::ACL::Match::Scalar object

    my $match = new Net::ACL::MatchMyPackage($args);

This is the constructor for Net::ACL::Match* objects.
It returns a reference to the newly created object.
It takes one argument, which should describe what to match.

=back

=head1 ACCESSOR METHODS

=over 4

=item match()

This function should match the data given as arguments (one or more) with
the data passed to the constructor and return either ACL_MATCH or
ACL_NOMATCH as exported by the ":rc" exporter symbol of
Net::ACL::Rule.

=item index()

This function returns the argument number that matched any sub-class.
Called with an argument, the argument is used as the new value.

=back

=head1 SEE ALSO

Net::ACL::Rule, Net::ACL,
Net::ACL::Match::IP, Net::ACL::Match::Prefix,
Net::ACL::Match::List, Net::ACL::Match::Scalar,
Net::ACL::Match::Regexp, Net::ACL::Match::Member

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End Package Net::ACL::Match ##
 
1;
