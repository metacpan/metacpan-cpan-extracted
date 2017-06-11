use utf8;
package Net::Etcd::Lease;

use strict;
use warnings;

use Moo;
use Types::Standard qw(Str Int Bool HashRef ArrayRef);
use Data::Dumper;
use Carp;
use JSON;

with 'Net::Etcd::Role::Actions';

use namespace::clean;

=head1 NAME

Net::Etcd::Lease

=cut

our $VERSION = '0.009';

=head1 DESCRIPTION

LeaseGrant creates a lease which expires if the server does not receive a keepAlive within
a given time to live period. All keys attached to the lease will be expired and deleted if
the lease expires. Each expired key generates a delete event in the event history.

=head1 ACCESSORS

=head2 endpoint

=cut

has endpoint => (
    is      => 'rwp',
    isa     => Str,
);

=head2 TTL

TTL is the advisory time-to-live in seconds.

=cut

has TTL => (
    is       => 'ro',
    isa      => Str,
);

=head2 ID

ID is the requested ID for the lease. If ID is set to 0, the lessor chooses an ID.

=cut

has ID => (
    is       => 'ro',
    coerce   => sub { return $_[0]; },
);

=head2 keys

keys is true to query all the keys attached to this lease.

=cut

has keys => (
    is       => 'ro',
    isa      => Bool,
    coerce => sub { no strict 'refs'; return $_[0] ? JSON::true : JSON::false }
);

=head1 PUBLIC METHODS

=head2 grant

LeaseGrant creates a lease which expires if the server does not receive a keepAlive within
a given time to live period. All keys attached to the lease will be expired and deleted if
the lease expires. Each expired key generates a delete event in the event history.


    $etcd->lease({ name =>'foo' password => 'bar' })->grant

=cut

sub grant {
    my $self = shift;
    $self->{endpoint} = '/lease/grant';
    confess 'TTL and ID are required for ' . __PACKAGE__ . '->grant'
      unless ($self->{ID} &&  $self->{TTL});
    $self->request;
    return $self;
}

=head2 revoke

LeaseRevoke revokes a lease. All keys attached to the lease will expire and be deleted.

    $etcd->lease({{ ID => 7587821338341002662 })->revoke

=cut

sub revoke {
    my $self = shift;
    $self->{endpoint} = '/kv/lease/revoke';
    confess 'ID is required for ' . __PACKAGE__ . '->revoke'
      unless $self->{ID};
    $self->request;
    return $self;
}

=head2 ttl

LeaseTimeToLive retrieves lease information.

    $etcd->lease({{ ID => 7587821338341002662, keys => 1 })->ttl

=cut

sub ttl {
    my $self = shift;
    $self->{endpoint} = '/kv/lease/timetolive';
    confess 'ID is required for ' . __PACKAGE__ . '->ttl'
      unless $self->{ID};
    $self->request;
    return $self;
}


=head2 keepalive

LeaseKeepAlive keeps the lease alive by streaming keep alive requests from the client
to the server and streaming keep alive responses from the server to the client."

    $etcd->lease({{ ID => 7587821338341002662 })->keepalive

=cut

sub keepalive {
    my $self = shift;
    $self->{endpoint} = '/lease/keepalive';
    confess 'ID is required for ' . __PACKAGE__ . '->keepalive'
      unless $self->{ID};
    $self->request;
    return $self;
}

1;
