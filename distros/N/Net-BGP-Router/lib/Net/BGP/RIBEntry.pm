#!/usr/bin/perl

# $Id: RIBEntry.pm,v 1.5 2003/06/02 11:50:12 unimlo Exp $

package Net::BGP::RIBEntry;

use strict;
use vars qw( $VERSION @ISA );

## Inheritance and Versioning ##

@ISA = qw ( );
$VERSION = '0.04';

## Module Imports ##

use Carp;
use Scalar::Util qw(blessed);

## Public Class Methods ##

sub new
{
 my $class = shift();
 my ($arg, $value);

 my $this = {
        _prefix  => undef,
        _in      => {},
        _local   => undef,
        _out     => {},
	_peers   => {},
	_force   => 0
    };

 bless($this, $class);

 while ( defined($arg = shift()) )
  {
   $value = shift();

   if ( $arg =~ /prefix/i )
    {
     $this->{_prefix} = $value;
    }
   else
    {
     confess("unrecognized argument $arg\n");
    }
  }
 return $this;
}

sub clone
{
 my $proto = shift;
 my $class = ref $proto || $proto;
 $proto = shift unless ref $proto;

 my $clone = {};

 $clone->{_prefix} = $proto->{_prefix};
 foreach my $key (qw( _in _out ))
  {
   @{$clone->{$key}}{keys %{$proto->{$key}}} =
	map { defined $_ ? $_->clone : undef; }
		values(%{$proto->{$key}});
  };
 $clone->{_local} = defined $proto->{_local} ? $proto->{_local}->clone : undef;

 $clone->{_peers} = $proto->{_peers}; # No reason to copy!

 return ( bless($clone, $class) );
}

## Public Object Methods ##

sub add_peer
{
 my ($this,$peer,$dir) = @_;
 $dir = $dir =~ /in/i ? '_in' : '_out';
 $this->{$dir}->{$peer} = undef;
 $this->{_force} = 1 if $dir eq '_out';
}

sub remove_peer
{
 my ($this,$peer,$dir) = @_;
 $dir = $dir =~ /in/i ? '_in' : '_out';
 delete $this->{$dir}->{$peer};
}

sub prefix
{
 my $this = shift;

 $this->{_prefix} = @_ ? shift : $this->{_prefix};

 return ( $this->{_prefix} );
}

sub local
{
 return shift->{_local};
};

sub in
{
 return shift->{_in};
};

sub out
{
 return shift->{_out};
};

sub update_in
{
 my ($this,$peer,$nlri) = @_;
 $this->{_in}->{$peer} = $nlri;
 return $this;
}

sub update_local
{
 my ($this,$policy) = @_;

 croak "argument should be a Net::BGP::Policy"
	unless (! defined $policy) || ((blessed $policy) && $policy->isa('Net::BGP::Policy'));

 my @nlris = defined $policy
	? @{$policy->in($this->{_prefix},$this->{_in})}
	: grep { $_; } values %{$this->{_in}}; # grep removes undef!


 my $old = $this->{_local};

 ($this->{_local}) = sort { $a <=> $b } @nlris;

 return ($old eq $this->{_local}) ? 0 : 1;
}

sub update_out
{
 my ($this,$policy) = @_;

 my $newout_hr;
 if (defined $policy)
  {
   croak "argument should be a Net::BGP::Policy"
	unless blessed $policy && $policy->isa('Net::BGP::Policy');
   $newout_hr = $policy->out($this->{_prefix},$this->{_local});
  }
 else
  {
   foreach my $peer (keys %{$this->{_out}})
    {
     $newout_hr->{$peer} = $this->{_local};
    };
  }; 

 my $changes_hr;

 # Peers not returned are not changed! Thats a feature - not a bug!

 # Look for changes! 
 foreach my $peer (keys %{$newout_hr})
  {
   # Was not and is not!
   next if ((! defined $this->{_out}->{$peer})
         && (! defined $newout_hr->{$peer}));

   # Are both there - and they are the same!
   next if ((defined $this->{_out}->{$peer})
             && (defined $newout_hr->{$peer})
             && ($this->{_out}->{$peer} eq $newout_hr->{$peer}));

   # We got a change!
   $changes_hr->{$peer} = $newout_hr->{$peer};
   $this->{_out}->{$peer} = $newout_hr->{$peer};
  };

 return $changes_hr;
}

sub handle_changes
{
 my ($this,$policy) = @_;
 return -1 unless $this->update_local($policy) || $this->{_force};
 $this->{_force} = 0;
 my $changes_hr = $this->update_out($policy);
 my $changes = 0;
 foreach my $to_peer (keys %{$changes_hr})
  {
   my $update = defined $changes_hr->{$to_peer}
       ? new Net::BGP::Update($changes_hr->{$to_peer},[$this->{_prefix}],undef)
       : new Net::BGP::Update(Withdraw => [$this->{_prefix}]);
   renew Net::BGP::Peer($to_peer)->update($update);
   $changes += 1;
  };
 return $changes;
}

sub asstring
{
 my $this = shift;
 my $res = $this->{_prefix} . ":\tLocal:\t" . $this->{_local}->asstring . "\n";
 foreach my $peer (keys %{$this->{_in}})
  {
   my $n = $this->{_in}->{$peer};
   $res .= "\tIN:\t" . renew Net::BGP::Peer($peer)->asstring . ': ' .
	 (defined $n ? $n->asstring : 'n/a') . "\n";
  };
 foreach my $peer (keys %{$this->{_out}})
  {
   my $n = $this->{_out}->{$peer};
   $res .= "\tOUT:\t" . renew Net::BGP::Peer($peer)->asstring . ': ' .
	 (defined $n ? $n->asstring : 'n/a') . "\n";
  };
 return $res;
}

=pod

=head1 NAME

Net::BGP::RIBEntry - Class representing an entry in a BGP RIB

=head1 SYNOPSIS

    use Net::BGP::RIBEntry;

    # Constructor
    $entry = new Net::BGP::RIBEntry(
        Prefix		=> '10.0.0.1'
    );

    # Object Copy
    $clone = $entry->clone();

    # Accessor Methods
    $entry->add_peer($peer,$dir);
    $entry->remove_peer($peer,$dir);

    $entry           = $entry->update_in($peer,$nlri);
    $has_changed     = $entry->update_local($policy);
    $changes_hashref = $entry->update_out($policy);

    $has_changed     = $entry->handle_changes($policy)

    $prefix          = $entry->prefix($prefix);

    $nlri            = $entry->local;
    $nlri_hashref    = $entry->in;
    $nlri_hashref    = $entry->out;

    $string          = $entry->asstring;


=head1 DESCRIPTION

This module implement a class representing an entry in a BGP Routing
Information Base.
It stores the prefix that the entry represents as well as 3 categories of
network layer reachability information (NLRI). Each NLRI is represented as
an L<Net::BGP::NLRI|Net::BGP::NLRI> object:

=over 4

=item IN - An NLRI object for each peer that has sent an UPDATE regarding this prefix.

=item Local - The preferred of the policy processed available NLRIs from the I<IN> RIB.

=item OUT - An NLRI object for each outgoing peer representing the processed I<Local> NLRI.

=back

=head1 CONSTRUCTOR

=over 4

=item new() - create a new Net::BGP::RIBEntry object

    $entry = new Net::BGP::RIBEntry(
        Prefix          => '10.0.0.1'
    );

This is the constructor for Net::BGP::RIBEntry object. It returns a
reference to the newly created object. The following named parameter may
be passed to the constructor:

=over 4

=item Prefix

This parameter corresponds to the prefix the RIB Entry represents.

=back

=back

=head1 OBJECT COPY

=over 4

=item clone() - clone a Net::BGP::RIBEntry object

    $clone = $nlri->clone();

This method creates an exact copy of the Net::BGP::RIBEntry object.

=back

=head1 ACCESSOR METHODS

=over 4

=item add_peer()

=item remove_peer()

Both add_peer() and remove_peer() takes two arguments: The peer object and
the direction of the peer (C<in> or C<out>).

=item update_in()

This method updates the RIB IN part of the object. The first argument is the
peer object that received the BGP UPDATE message and the second argument is
an NLRI object corresponding the received UPDATE message.

The method returns the RIBEntry object.

=item update_local()

This method applies the incoming policy and executes the route selection
process of BGP. If no arguments (or a undefined value), no policy will be
used. Otherwise the argument should be a Net::BGP::Policy object - or
something inherited from that.

After applying the given policy, the selection process updates the Local RIB
with the best available NLRI.

The return value is true if the Local RIB is changed, otherwise false.

=item update_out()

This method applies the outgoing policy to the Local RIB and updates the
OUT RIB accordingly. If no arguments (or a undefined value), no policy will be
used. Otherwise the argument should be a Net::BGP::Policy object - or
something inherited from that.

=item handle_changes()

This method combines the update_local() and update_out() methods and generates
UPDATE messages for each change and sends them to the peers. It takes a
optional policy as first argument which are used in the calls to
update_local() and update_out().

It returns -1 if no changes has happend. Otherwise it returns the number of
changes send.

=item prefix()

This mothod returns the prefix the RIB Entry represent. It an argument is
given, the prefix will be replaced with that value.

=item local()

This method returns the currently selected NLRI or undefined if no NLRIs are
available.

=item in()

=item out()

Both the in() and out() method returns a reference to a hash indexed on peers
containing Net::BGP::NLRI objects coresponding the the incoming or outgoing
UPDATE message data.

=item asstring()

This method returns a print-friendly string describing the RIB entry.

=back

=head1 SEE ALSO

Net::BGP, Net::BGP::RIB, Net::BGP::NLRI, Net::BGP::Update, Net::BGP::Policy

=head1 AUTHOR

Martin Lorensen <bgp@martin.lorensen.dk>

=cut

## End Package Net::BGP::RIBEntry ##

1;
