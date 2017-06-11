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

with 'Net::Etcd::Role::Actions';
use namespace::clean;

=head1 NAME

Net::Etcd::KV

=cut

our $VERSION = '0.009';

=head1 DESCRIPTION

Key Value role providing easy access to Put and Range classes

=cut

=head1 PUBLIC METHODS

=head2 range

Range gets the keys in the range from the key-value store.

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
    $range->request;
    return $range;
}

=head2 put

Put puts the given key into the key-value store. A put request increments
the revision of the key-value store and generates one event in the event
history.

    $etcd->range({key =>'test0', range_end => 'test100'})

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
    $put->request;
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
    $txn->request;
    return $txn;
}

1;
