use utf8;
package Net::Etcd::KV;

use strict;
use warnings;

=encoding utf8

=cut
use Moo::Role;
use Types::Standard qw(Str Int Bool HashRef ArrayRef);
use Net::Etcd::KV::Put;
use Net::Etcd::KV::Range;
use Net::Etcd::KV::DeleteRange;
use Net::Etcd::KV::Txn;
use Net::Etcd::KV::Op;
use Net::Etcd::KV::Compare;

with 'Net::Etcd::Role::Actions';
use namespace::clean;

=head1 NAME

Net::Etcd::KV

=cut

our $VERSION = '0.018';

=head1 DESCRIPTION

Key Value role providing easy access to Put and Range classes

=cut

=head1 PUBLIC METHODS

=head2 range

Range gets the keys in the range from the key-value store.

    # get range
    $etcd->range({key =>'test0', range_end => 'test100'})

=cut

sub range {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    my $range = Net::Etcd::KV::Range->new(
        endpoint => '/kv/range',
        etcd     => $self,
        cb       => $cb,
        ( $options ? %$options : () ),
    );
    $range->request unless $range->hold;
    return $range
}

=head2 deleterange

DeleteRange deletes the given range from the key-value store. A delete
request increments the revision of the key-value store and generates a
delete event in the event history for every deleted key.

    $etcd->deleterange({key => 'test0'})

=cut

sub deleterange {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    my $delete_range = Net::Etcd::KV::DeleteRange->new(
        endpoint => '/kv/deleterange',
        etcd     => $self,
        cb       => $cb,
        ( $options ? %$options : () ),
    );
    $delete_range->request unless $delete_range->hold;
    return $delete_range;
}

=head2 put

Put puts the given key into the key-value store. A put request increments
the revision of the key-value store and generates one event in the event
history.

    $etcd->put({key =>'test0', value=> 'bar'})

=cut

sub put {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    my $put = Net::Etcd::KV::Put->new(
        endpoint => '/kv/put',
        etcd     => $self,
        cb       => $cb,
        ( $options ? %$options : () ),
    );
    $put->request unless $put->hold;
    return $put;
}

=head2 txn

Txn processes multiple requests in a single transaction. A txn request increments
the revision of the key-value store and generates events with the same revision for
every completed request. It is not allowed to modify the same key several times
within one txn.

=cut

sub txn {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    my $txn = Net::Etcd::KV::Txn->new(
        %$self,
        endpoint => '/kv/txn',
        etcd     => $self,
        cb       => $cb,
        ( $options ? %$options : () ),
    );
    return $txn->create; 
}

=head2 op

=cut

sub op {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    my $op = Net::Etcd::KV::Op->new(
        %$self,
        ( $options ? %$options : () ),
    );
    return  $op->create;
}

=head2 compare

=cut

sub compare {
    my ( $self, $options ) = @_; 
    my $cb = pop if ref $_[-1] eq 'CODE';
    my $cmp = Net::Etcd::KV::Compare->new(
        %$self,
        ( $options ? %$options : () ),
    );
    return $cmp->json_args;
}

1;
