#!/usr/bin/perl -wT

# $Id: Router.pm,v 1.15 2003/06/02 15:01:17 unimlo Exp $

package Net::BGP::Router;

use strict;
use warnings;
use vars qw( $VERSION @ISA );

## Inheritance and Versioning ##

$VERSION = '0.04';

## Import modules ##

use Net::BGP::RIB;
use Scalar::Util qw(weaken);
use Carp;

## Public Class Methods ##

sub new
{
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $this = {
        _name       => undef,
        _RIB        => new Net::BGP::RIB,
	_inpeers    => {},
	_outpeers   => {},
        _policy     => undef
    };

    while ( defined(my $arg = shift) ) {
        my $value = shift;

        if ( $arg =~ /name/i ) {
            $this->{_name} = $value;
        }
        elsif ( $arg =~ /policy/i ) {
            croak "Policy should be a Net::BGP::Policy or sub-class"
		unless $value->isa('Net::BGP::Policy');
            $this->{_policy} = $value;
        }
        else {
            croak "unrecognized argument $arg\n";
        }
    }

    bless($this, $class);
}

## Public Object Methods ##

sub add_peer
{
 my ($this,$peer,$dir,$acl) = @_;

 if ($dir =~ /(out|both)/i)
  {
   # Policy
   $this->{_policy}->set($peer,'out',$acl) if defined $this->{_policy};

   # RIB
   $this->{_RIB}->add_peer($peer,'out',$acl);

   # Refresh handler
   my $callbackrefresh  = sub { $this->_handle_refresh(@_); };
   $peer->set_refresh_callback($callbackrefresh);

   # Remember for destruction
   weaken($this->{_outpeers}->{$peer} = $peer);
  };

 if ($dir =~ /(in|both)/i)
  {
   # Policy
   $this->{_policy}->set($peer,'in',$acl) if defined $this->{_policy};

   # RIB
   $this->{_RIB}->add_peer($peer,'in',$acl);

   # Update handler
   my $callbackupdate   = sub { $this->_handle_update(@_); };
   $peer->set_update_callback($callbackupdate);

   # Reset handler
   my $callbackreset    = sub { $this->_handle_reset(@_); };
   $peer->set_reset_callback($callbackreset);

   # Remember for destruction
   weaken($this->{_inpeers}->{$peer} = $peer);
  };
}

sub remove_peer
{
 my ($this,$peer,$dir) = @_;

 if ($dir =~ /(out|both)/i)
  {
   # Callbacks
   $peer->set_refresh_callback(undef);

   # Policy
   $this->{_policy}->delete($peer,'out') if defined $this->{_policy};

   # RIB
   $this->{_RIB}->remove_peer($peer,'out',$this->{_policy});

   # Forget!
   delete $this->{_outpeers}->{$peer};
  };

 if ($dir =~ /(in|both)/i)
  {
   # Callbacks
   $peer->set_reset_callback(undef);
   $peer->set_update_callback(undef);

   # Policy
   $this->{_policy}->delete($peer,'in') if defined $this->{_policy};

   # RIB
   $this->{_RIB}->remove_peer($peer,'in',$this->{_policy});

   # Forget!
   delete $this->{_inpeers}->{$peer};
  };
}

sub set_policy
{
 my ($this,$policy,$peer,$dir) = @_;
 if (! defined $policy || $policy->isa('Net::ACL'))
  {
   croak "Need peer and direction when assigning or removing local policy" 
	unless defined $peer && defined $dir;
   croak "No global policy object to modify" unless defined $this->{_policy};
   $this->{_policy}->set($peer,$dir,$policy);
  }
 elsif ($policy->isa('Net::BGP::Policy'))
  {
   croak "No peer or direction allowed when asigning globel policy"
	if defined $peer || defined $dir;
   $this->{_policy} = $policy;
  }
 else
  {
   croak "Invalid policy - Need a Net::ACL, a Net::BGP::Policy, or a sub-class of these\n";
  };
}

sub DESTROY
{
 my $this = shift;
 foreach my $peer (values %{$this->{_outpeers}})
  {
   next unless defined $peer;
   $this->remove_peer($peer,'out');
  };
 foreach my $peer (values %{$this->{_inpeers}})
  {
   next unless defined $peer;
   $this->remove_peer($peer,'in');
  };
}

## Private Object Methods ##

sub _handle_update
{
 my ($this,$peer,$update) = @_;
 $this->{_RIB}->handle_update($peer,$update,$this->{_policy});
}

sub _handle_reset
{
 my ($this,$peer,$notif) = @_;
 # The notification packet itself is ignored - But peer is down when we get here!
warn "GOT RESET: " . $peer->asstring . "\n";
 $this->{_RIB}->reset_peer($peer,'in',$this->{_policy});
}

sub _handle_refresh
{
 my ($this,$peer,$refresh) = @_;
 # The refresh packet itself is ignored - No understading of Address Families yet...
warn "GOT REFRESH: " . $peer->asstring . "\n";
 $this->{_RIB}->reset_peer($peer,'out',$this->{_policy});
}

=pod

=head1 NAME

Net::BGP::Router - A BGP Router based on Net::BGP

=head1 SYNOPSIS

    use Net::BGP::Router;

    # Constructor
    $router = new Net::BGP::Router(
        Name		=> 'My very own router!',
	Policy		=> new Net::BGP::Policy
    );

    # Accessor Methods
    $router->add_peer($peer,'both',$acl);
    $router->remove_peer($peer,'both');
    $router->set_policy($policy);
    $router->set_policy($peer,'in',$acl);


=head1 DESCRIPTION

This module implement a BGP router. It uses L<Net::BGP|Net::BGP> objects for
the BGP sessions and a L<Net::BGP::RIB|Net::BGP::RIB> object to store the
routes. Policy are handled using a L<Net::BGP::Policy|Net::BGP::Policy> object.

=head1 CONSTRUCTOR

=over 4

=item new() - create a new Net::BGP::Router object

    $router = new Net::BGP::Router(
        Name		=> 'My very own router!',
	Policy		=> new Net::BGP::Policy
    );

This is the constructor for Net::BGP::Router object. It returns a
reference to the newly created object. The following named parameters may
be passed to the constructor:

=over 4

=item Name

This is the name of the router or router-context. This is for informational
use only.

=item Policy

This is the Net::BGP::Policy object used as policy. If not specified, no
policy will be used. Note that the Policy method set()
will be issued on every add_peer() and remove_peer(). Therefor there is no
reason to do this manualy before adding the peers.

=back

=back

=head1 ACCESSOR METHODS

=over 4

=item add_peer()

This method adds a peer to the router. The first argument is the peer object.
The second argument is the direction of the peer. A peer can either only
contribute with updates C<in>, only recieve updates C<out>, or both C<both>.
The third argument is optitional and is a peer/direction-specific policy as
a Net::ACL object.

=item remove_peer()

This medhod removes a peer from the router. The first argument is the peer
object. The second argument is the direction in which the peer should be
removed.

=item set_policy()

This medhod can either change the global policy or the policy for a peer in
some direction. The first argument is the policy object. If the policy object
is a Net::BGP::Policy object, it will be used as a new global policy. If it
is a Net::ACL object, it will be used as a peer policy for the peer object and
diraction specified as second and third argument.

=back

=head1 SEE ALSO

Net::BGP, Net::BGP::RIB, Net::BGP::Policy, Net::ACL

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End of Net::BGP::Router ##

1;
