=head1 NAME

Net::CIDR::Lookup::Tie

=head1 DESCRIPTION

This is a L<Tie::Hash|Tie::Hash> interface to L<Net::CIDR::Lookup|Net::CIDR::Lookup>, see there for
details.

The tied hash accepts net blocks as keys in the same syntax as
C<Net::CIDR::Lookup>'s C<add()> or C<add_range()> and stores arbitrary (with the
exception of C<undef>) scalar values under these. The same coalescing as in
C<Net::CIDR::Lookup> takes place, so if you add any number of different keys
you may end up with a hash containing I<less> keys if any mergers took place.

Of course you can retrieve the corresponding net block's value for any key that
is I<contained> within that block, so the number of possible lookup keys is
usually far greater than that of explicitly stored key/value pairs.

=head1 SYNOPSIS

  use Net::CIDR::Lookup::Tie;

  tie my %t, 'Net::CIDR::Lookup::Tie';
  $t{'192.168.42.0/24'}   = 1;    # Add first network
  $t{'192.168.43.0/24'}   = 1;    # Automatic coalescing to a /23
  $t{'192.168.41.0/24'}   = 2;    # Stays separate due to different value

  print $t{'192.168.42.100'};		 # prints "1"

  foreach(keys %h) { ... }			 # Do anything you'd do with a regular hash

=head1 METHODS

=cut

package Net::CIDR::Lookup::Tie;

use strict;
use warnings;
use Carp;
use Net::CIDR::Lookup;

use version 0.77; our $VERSION = version->declare('v1.0.0');

sub TIEHASH {   ## no critic (Subroutines::RequireArgUnpacking)
    my $class = shift;
    bless { tree => Net::CIDR::Lookup->new(@_) }, $class;
}

=head2 STORE

Stores a value under a given key

=cut

sub STORE { ## no critic (Subroutines::RequireArgUnpacking)
    my $self = shift;
    undef $self->{keys};
    if($_[0] =~ /-/) {
        $self->{tree}->add_range(@_);
    } else {
        $self->{tree}->add(@_);
    }
}

=head2 FETCH

Fetches the value stored under a given key

=cut

sub FETCH {
    my ($self, $key) = @_;
    $self->{tree}->lookup($key);
}
 
=head2 FIRSTKEY

Gets the first key in the hash. Used for iteration with each()

=cut

sub FIRSTKEY {
    my $self = shift;
    $self->_updkeys;
    each %{$self->{keys}};
}

=head2 NEXTKEY

Gets the next key from the hash. Used for iteration with each()

=cut

sub NEXTKEY {
    each %{shift->{keys}};
}

=head2 EXISTS

Tests if a key is in the hash. Also returns true for blocks or addresses
contained within a block that was actually stored.

=cut

sub EXISTS {
    my ($self, $key) = @_;
    $self->_updkeys;
    exists $self->{keys}{$key};
}

=head2 DELETE

Delete a key from the hash. Note that the same restrictions as for Net::CIDR::Lookup
regarding netblock splitting apply!

=cut

sub DELETE {
    carp('Deletions are not supported by tied ' . __PACKAGE__ . ' objects yet!');
}

=head2 CLEAR

Deletes all keys and their values.

=cut

sub CLEAR {
    my $self = shift;
    $self->{tree}->clear;
}

=head2 SCALAR

Returns the number of keys in the hash

=cut

sub SCALAR {
    my $self = shift;
    $self->_updkeys;
    scalar keys %{$self->{keys}};
}

=head2 _updkeys

Private method to update the internal key cache used for iteration

=cut

sub _updkeys {
    my $self = shift;

    if(defined $self->{keys}) {
        keys %{$self->{keys}};                  # Call in void context to reset
    } else {
        $self->{keys} = $self->{tree}->to_hash; # Recreate hash
    }
}
1;
