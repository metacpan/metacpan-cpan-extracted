use utf8;
package Net::Etcd::Maintenance;

use strict;
use warnings;

=encoding utf8

=cut

use Moo;
use Types::Standard qw(Str);

with 'Net::Etcd::Role::Actions';
use namespace::clean;

=head1 NAME

Net::Etcd::Maintenance

=cut

our $VERSION = '0.017';
=head1 SYNOPSIS

    # defrag member's backend database
    $defrag = $etcd->maintenance()->defragment;

    # check status
    $status = $etcd->maintenance()->status;

    # member version
    $status = $etcd->version;

=head1 DESCRIPTION

Provides support for maintenance related actions.

=cut

=head1 ACCESSORS

=head2 endpoint

=cut

has endpoint => (
    is      => 'rwp',
    isa     => Str,
);

=head1 PUBLIC METHODS

=head2 snapshot

Snapshot sends a snapshot of the entire backend from a member over a stream to a client.

=cut

sub snapshot {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    $self->{endpoint} = '/maintenance/snapshot';
    $self->{json_args} = '{}';
    $self->request;
    return $self;
}

=head2 status

Status gets the status of the member.

=cut

sub status {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    $self->{endpoint} = '/maintenance/status';
    $self->{json_args} = '{}';
    $self->request;
    return $self;
}

=head2 defragment

Defragment defragments a member's backend database to recover storage space.

=cut

sub defragment {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    $self->{endpoint} = '/maintenance/defragment';
    $self->{json_args} = '{}';
    $self->request;
    return $self;
}

=head2 version

Returns the member version.

=cut

sub version {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    my $status = $self->status;
    if ( $status->is_success ) {
        return $status->content->{version};
    }
    return;
}

1;
