#!/usr/bin/perl

# $Id: List.pm,v 1.14 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::Match::List;

use strict;
use vars qw( $VERSION @ISA );

## Inheritance and Versioning ##

@ISA     = qw( Net::ACL::Match );
$VERSION = '0.07';

## Module Imports ##

use Carp;
use Scalar::Util qw( blessed );
use Net::ACL::Match;
use Net::ACL::Rule qw( :rc :action );
use Net::ACL::Bootstrap;

## Public Class Methods ##

sub new
{
 my $proto = shift;
 my $class = ref $proto || $proto;

 @_ = @{$_[0]} if (scalar @_ == 1) && (ref $_[0] eq 'ARRAY');

 my $this = {
        _lists => [],
	_index => shift
  };

 croak "Index should be a number" unless $this->{_index} =~ /^[0-9]$/;

 bless($this, $class);

 $this->add_list(@_);

 croak 'Need at least one access-list to match' unless scalar  $this->{_lists};

 return $this;
}

## Public Object Methods ##

sub add_list
{
 my $this = shift;
 if (blessed $_[0])
  {
   push(@{$this->{_lists}}, shift);
   $this->add_list(@_) unless scalar @_ == 0;
  }
 elsif (ref $_[0] eq 'ARRAY')
  {
   $this->add_list(shift);
   $this->add_list(@_) unless scalar @_ == 0;
  }
 elsif (ref $_[0] eq 'HASH')
  {
   my $d = shift;
   $this->add_list(renew Net::ACL::Bootstrap(%{$d}));
   $this->add_list(@_) unless scalar @_ == 0;
  }
 else
  {
   $this->add_list(renew Net::ACL::Bootstrap(@_));
  };
}

sub match
{
 my $this = shift;
 my @data = @_;
 foreach my $list (@{$this->{_lists}})
  {
   return ACL_NOMATCH unless $list->match($data[$this->{_index}]) == ACL_PERMIT;
  }
 return ACL_MATCH;
}

sub type
{
 my $this = shift;
 return unless scalar @{$this->{_lists}};
 return $this->{_lists}->[0]->type;
}

sub names
{
 my $this = shift;
 return map { $_->name; } @{$this->{_lists}};
}

## POD ##

=pod

=head1 NAME

Net::ACL::Match::List - Class matching data against one or more access-lists

=head1 SYNOPSIS

    use Net::ACL::Match::List;

    # Constructor
    $match = new Net::ACL::Match::List(2, [
	Type	=> 'prefix-list'
	Name	=> 42
	] );

    # Accessor Methods
    $rc = $match->match('127.0.0.0/20');

=head1 DESCRIPTION

This module match data against one or more access-lists. It only matches if
data if data is permitted by all access-lists.

=head1 CONSTRUCTOR

=over 4

=item new() - create a new Net::ACL::Match::List object

    $match = new Net::ACL::Match::List(2, [
	Type	=> 'prefix-list'
	Name	=> 42
	] );

This is the constructor for Net::ACL::Match::List objects. It
returns a reference to the newly created object. The first
argument is the index of the element that should be matched.

The second argument can have one of the following types:

=over 4

=item Net::ACL

An access-list to be matched against.

=item HASH reference

A reference to a hash passed to Net::ACL->renew()

=item SCALAR

A scalar passed to Net::ACL->renew()

=item ARRAY reference

A reference to an array one of the above 3 types. Used
to match multiple lists.

=back

=back

=head1 ACCESSOR METHODS

=over 4

=item match()

The match method verifies if the data is permitted by all access-lists
supplied to the constructor. Returns ACL_MATCH if it does, otherwise
ACL_NOMATCH.

=item names()

Return a list with all match lists names.

=item type()

Returns the type of the first list that is matched - or C<undef> if no lists are
matched.

=back

=head1 SEE ALSO

Net::ACL::Match, Net::ACL::Rule, Net::ACL

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End Package Net::ACL::Match::List ##
 
1;
