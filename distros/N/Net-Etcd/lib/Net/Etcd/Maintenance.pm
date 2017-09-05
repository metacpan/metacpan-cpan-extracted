use utf8;
package Net::Etcd::Maintenance;

use strict;
use warnings;

=encoding utf8

=cut
use Moo;

with 'Net::Etcd::Role::Actions';
use namespace::clean;

=head1 NAME

Net::Etcd::Maintenance

=cut

our $VERSION = '0.014';

=head1 DESCRIPTION

Provides support for maintenance related actions.

=cut

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

1;
