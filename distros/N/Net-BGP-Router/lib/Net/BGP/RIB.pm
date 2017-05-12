#!/usr/bin/perl

# $Id: RIB.pm,v 1.9 2003/06/02 15:01:17 unimlo Exp $

package Net::BGP::RIB;

use strict;
use vars qw( $VERSION );
use Carp;

## Inheritance and Versioning ##

$VERSION = '0.04';

## Module Import ##

use Net::Patricia;
use Net::BGP::RIBEntry;
use Net::BGP::Policy;

## Public Class Methods ##

sub new
{
 my $class = shift();
 my ($arg, $value);

 my $this = {
	_table => new Net::Patricia,
  };

 bless($this, $class);

 return $this;
}

## Public Object Methods ##

sub add_peer
{
 my ($this,$peer,$dir,$policy) = @_;
 $this->{_table}->climb( sub
  {
   my $re = shift;
   $re->add_peer($peer,$dir);
   $re->handle_changes($policy);
  } );
}

sub reset_peer
{
 shift->add_peer(@_); # Just set to undef - same thing!
}

sub remove_peer
{
 my ($this,$peer,$dir,$policy) = @_;
 $this->{_table}->climb( sub
  {
   my $re = shift;
   return unless defined $re; # While in final cleanup
   $re->remove_peer($peer,$dir);
   $re->handle_changes($this,$policy);
  } );
}

sub handle_update
{
 my ($this,$peer,$update,$policy) = @_;

 my $nlri_hr = $update->ashash;
 foreach my $prefix (keys %{$nlri_hr}) 
  {
   my $entry = $this->{_table}->match_exact_string($prefix);
   unless (defined($entry))
    {
     $entry = new Net::BGP::RIBEntry(prefix => $prefix);
     $this->{_table}->add_string($prefix,$entry);
    };
   $entry->update_in($peer,$nlri_hr->{$prefix});
   $entry->handle_changes($policy);
  };
}

sub asstring
{
 my ($this) = shift;
 my $res = '';
 $this->{_table}->climb( sub { $res .= shift; } );
 return $res;
}

=pod

=head1 NAME

Net::BGP::RIB - Class representing BGP Routing Information Base (RIB)

=head1 SYNOPSIS

    use Net::BGP::RIB;

    # Constructor
    $rib = new Net::BGP::RIB();

    # Accessor Methods
    $rib->add_peer($peer,$dir,$policy);
    $rib->reset_peer($peer,$dir,$policy);
    $rib->remove_peer($peer,$dir,$policy);

    $rib->handle_update($peer,$update,$policy)

    $string          = $entry->asstring;


=head1 DESCRIPTION

This module implement a class representing an entry in a BGP Routing
Information Base. It stores individual RIB entries in
L<Net::BGP::RIBEntry|Net::BGP::RIBEntry> objects.

=head1 CONSTRUCTOR

=over 4

=item new() - create a new Net::BGP::RIB object

    $rib = new Net::BGP::RIB()

This is the constructor for Net::BGP::RIB object. It returns a reference to
the newly created object. All arguments are ignored.

=back

=head1 ACCESSOR METHODS

=over 4

=item add_peer()

=item reset_peer()

=item remove_peer()

All three methods takes a Net::BGP::Peer object as first argument. The second
should be the direction (C<in> or C<out>). The thirds is optional and is the
policy, a Net::BGP::Policy object.

add_peer() adds the peer to the RIB. remove_peer() removes the peer from the
RIB while reset_peer() clears information about NLRIs recieved or send to
the peer. All three might have the side effect that UPDATE messages are sent
to the peer or other peers in the RIB.

=item handle_update()

The handle_update() method handles updates of the RIB. It should have the
peer object of the peer that has recieved the UPDATE message as the first
argument. The second argument should be the Net::BGP::Update object recieved.
The third optional argument is the policy used.

=item asstring()

This method returns a print-friendly string describing the RIB.

=back

=head1 SEE ALSO

Net::BGP::RIBEntry, Net::BGP::Router, Net::Policy, Net::BGP::Update

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End Package Net::BGP::RIBEntry ##

1;
