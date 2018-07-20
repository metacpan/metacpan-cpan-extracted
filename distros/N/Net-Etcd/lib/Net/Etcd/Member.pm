use utf8;
package Net::Etcd::Member;

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

our $VERSION = '0.022';
=head1 SYNOPSIS

    # list members
    $members = $etcd->member()->list;

=head1 DESCRIPTION

Provides support for cluster member related actions.

=cut

=head1 ACCESSORS

=head2 endpoint

=cut

has endpoint => (
    is      => 'rwp',
    isa     => Str,
);

=head1 PUBLIC METHODS

=head2 list

lists all the members in the cluster.

=cut

sub list {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    $self->{endpoint} = '/cluster/member/list';
    $self->{json_args} = '{}';
    $self->request;
    return $self;
}

1;
