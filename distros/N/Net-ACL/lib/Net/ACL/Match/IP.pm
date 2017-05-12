#!/usr/bin/perl

# $Id: IP.pm,v 1.15 2003/06/06 18:45:02 unimlo Exp $

package Net::ACL::Match::IP;

use strict;
use vars qw( $VERSION @ISA );

## Inheritance and Versioning ##

@ISA     = qw( Net::ACL::Match );
$VERSION = '0.07';

## Module Imports ##

use Carp;
use Net::ACL::Match;
use Net::ACL::Rule qw( :rc );
use Net::Netmask;

## Public Class Methods ##

sub new
{
 my $proto = shift;
 my $class = ref $proto || $proto;

 @_ = @{$_[0]} if (scalar @_ == 1) && (ref $_[0] eq 'ARRAY');

 my $this = bless( {
	_index => undef,
        _net => undef
	}, $class);

 $this->{_index} = shift;
 croak "Index not a number ($this->{_index})" unless $this->{_index} =~ /^[0-9]+$/;

 croak "Missing network data" unless scalar @_ > 0;

 $this->{_net} = new Net::Netmask(@_);

 croak $this->{_net}->{'ERROR'} if defined $this->{_net}->{'ERROR'};

 return $this;
}

## Public Object Methods ##

sub match
{
 my $this = shift;
 return $this->{_net}->match($_[$this->{_index}]) ? ACL_MATCH : ACL_NOMATCH;
}

sub net
{
 my $this = shift;
 $this->{_net} = @_ ? ((ref $_[0] eq 'Net::Netmask') ? $_[0] : new Net::Netmask(@_)) : $this->{_net};
 return $this->{_net};
}

## POD ##

=pod

=head1 NAME

Net::ACL::Match::IP - Class matching IP addresses against an IP or network

=head1 SYNOPSIS

    use Net::ACL::Match::IP;

    # Constructor
    $match = new Net::ACL::Match::IP(1,'10.0.0.0/8');

    # Accessor Methods
    $netmaskobj = $match->net($netmaskobj);
    $netmaskobj = $match->net($net);
    $index = $match->index($index);
    $rc = $match->match($ip);

=head1 DESCRIPTION

This module is just a wrapper of the Net::Netmask module to allow it to
operate automatically with L<Net::ACL::Rule|Net::ACL::Rule>.

=head1 CONSTRUCTOR

=over 4

=item new() - create a new Net::ACL::Match::IP object

    $match = new Net::ACL::Match::IP(1,'10.0.0.0/8');

This is the constructor for Net::ACL::Match::IP objects. It returns a
reference to the newly created object. The first argument is the argument
number of the match method that should be matched. The remaining arguments
is parsed directly to the constructor of Net::Netmask.

=back

=head1 ACCESSOR METHODS

=over 4

=item net()

The net method returns the Net::Netmask object representing the network
matched. If called with a Net::Netmask object, the net used for matching is
changed to that object. If called with a anything else, the Net::Netmask
constructor will be used to convert it to a Net::Netmask object.

=item index()

The index method returns the index of the argument that will be matched.
If called with an argument, the index is changed to that argument.

=item match()

The match method invoke the match() method of the Net::Netmask object constructed
by new(). The index value defines which argument is passed on to new().

=back

=head1 SEE ALSO

Net::Netmask, Net::ACL,
Net::ACL::Rule, Net::ACL::Match

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End Package Net::ACL::Match::IP ##
 
1;
