#!/usr/bin/perl

# $Id: Policy.pm,v 1.3 2003/06/02 11:50:12 unimlo Exp $

package Net::BGP::Policy;

use strict;
use vars qw( $VERSION @ISA );

## Inheritance and Versioning ##

@ISA = qw ( );
$VERSION = '0.04';

## Module Imports ##

use Carp;
use Net::BGP::Peer;
use Scalar::Util qw(weaken);

## Public Class Methods ##

sub new
{
 my $proto = shift || __PACKAGE__;
 my $class = ref $proto || $proto;

 my $this = {
	_in    => {},
	_out   => {},
	_peer  => {}
    };

 bless($this, $class);

 return $this;
}

## Public Object Methods ##

sub set
{
 my ($this,$peer,$dir,$policy) = @_;
 croak "Set policy need 3 arguments!" if (scalar @_ < 3);
 $dir = $dir =~ /in/i ? '_in' : '_out';
 if (scalar @_ == 3) # Remove peer if no 3rd argument
  {
   delete $this->{$dir}->{$peer};
   return;
  }
 croak "Unknown policy type - Should be a Net::ACL object"
	unless $policy->isa('Net::ACL');
 $peer = renew Net::BGP::Peer($peer) unless ref $peer;
 croak "Peer unknown - Should be a Net::BGP::Peer object"
	unless $peer->isa('Net::BGP::Peer');
 $this->{$dir}->{$peer} = $policy;
 weaken($this->{_peer}->{$peer} = $peer);
}

sub delete
{
 croak "delete method needs 2 arguments: The peer and the direction"
	unless scalar @_ == 3;
 shift->set(@_);
}

sub out
{
 my ($this,$prefix,$nlri) = @_;

 my %newout;
 unless (defined $nlri)
  {
   foreach my $peer (keys %{$this->{_out}})
    {
     $newout{$peer} = undef;
    }
  }
 else
  {
   foreach my $peer (keys %{$this->{_out}})
    {
     my $p = $this->{_out}->{$peer};
     # query should NOT modify the $nlri object itself!
     $newout{$peer} = defined $p
	? ($p->query($prefix,$nlri,$this->{_peer}->{$peer}))[2]
	: $nlri;
    };
  };
 return \%newout;
}

sub in
{
 my ($this,$prefix,$nlri) = @_;

 my @nlri;

 foreach my $peer (keys %{$nlri})
  {
   my $n = $nlri->{$peer};
   next unless defined($n);
   my $p = $this->{_in}->{$peer};
   # query should NOT modify the $n(lri) object itself!
   $n = ($p->query($prefix,$n,$this->{_peer}->{$peer}))[2] if defined($p);
   push(@nlri,$n) if defined $n;
  };
 return \@nlri;
}

=pod

=head1 NAME

Net::BGP::Policy - Class representing a Global BGP Routing Policy

=head1 SYNOPSIS

    use Net::BGP::Policy;

    # Constructor
    $policy = new Net::BGP::Policy();

    # Accessor Methods
    $policy->set($peer, 'in', $acl);
    $policy->delete($peer,'out');

    $nlri_array_ref  = $policy->in($prefix, { $peer => $nlri, ... } );
    $out_hash_ref    = $policy->out($prefix, $nlri );

=head1 DESCRIPTION

This module implement a class representing a global BGP Routing Policy. It
does so using L<Net::ACL route-maps|Net::ACL::RouteMapRule>.

=head1 CONSTRUCTOR

=over 4

=item new() - create a new Net::BGP::Policy object

    $policy = new Net::BGP::Policy();

This is the constructor for Net::BGP::Policy object. It returns a
reference to the newly created object. It ignores all arguments.

=back

=head1 ACCESSOR METHODS

=over 4

=item set()

This method is used to configure a policy for a peer in a direction. It takes
two or three arguments. The first is the peer, the second is the direction
(C<in> or C<out>). The third is the policy which should be a Net::ACL
route-map (or an object inherited from Net::ACL). The rules of the route-map
should be like Net::ACL::RouteMapRule objects. If the third parameter is
undefined, no policy will be used for the peer. If the third parameter is not
pressent, the peer will not get updates.

=item delete()

This method is used to remove a peer from the policy in a direction. It takes
two arguments. The first is the peer, the second is the direction (C<in> or
C<out>).

=item in()

The in() method executes the policy for incomming updates. The first argument
is the prefix, the second should be an hash reference. The hash reference
is indexed on peers with values of NLRI objects avaible from that peer.

The method returns a list of NLRIs.

=item out()

The out() method executes the policy for outgoing updates. The first argument
is the prefix, the second is the NLRI object.

The method returns a reference to a hash of NLRIs indexed on peers.

=back

=head1 SEE ALSO

Net::BGP, Net::BGP::RIB, Net::BGP::NLRI, Net::BGP::Router, Net::ACL

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End Package Net::BGP::Policy ##

1;
