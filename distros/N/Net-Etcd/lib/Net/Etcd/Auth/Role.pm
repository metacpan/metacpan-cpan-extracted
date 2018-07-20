use utf8;
package Net::Etcd::Auth::Role;

use strict;
use warnings;

use Moo;
use Types::Standard qw(Str Int Bool HashRef ArrayRef);
use MIME::Base64;
use Carp;
use JSON;

with 'Net::Etcd::Role::Actions';

use namespace::clean;

=head1 NAME

Net::Etcd::Auth::Role

=cut

our $VERSION = '0.022';

=head1 DESCRIPTION

Role

=head2 endpoint

=cut

has endpoint => (
    is       => 'rwp',
    isa      => Str,
);

=head2 name

name of role

=cut

has name => (
    is       => 'ro',
    isa      => Str,
);

=head2 role

name of role

=cut

has role => (
    is       => 'ro',
    isa      => Str,
);

=head2 add

Add role

=cut

sub add {
    my ($self) = @_;
    confess 'name required for ' . __PACKAGE__ . '->add'
      unless $self->{name};
    $self->{endpoint} = '/auth/role/add';
    $self->request;
    return $self;
}

=head2 delete

Delete role

=cut

sub delete {
    my ($self) = @_;
    confess 'role required for ' . __PACKAGE__ . '->delete'
      unless $self->{role};
    $self->{endpoint} = '/auth/role/delete';
    $self->request;
    return $self;
}

=head2 get

Get role

=cut

sub get {
    my ($self) = @_;
    confess 'name required for ' . __PACKAGE__ . '->get'
      unless $self->{role};
    $self->{endpoint} = '/auth/role/get';
    $self->request;
    return $self;
}

=head2 list

List roles

=cut

sub list {
    my ($self) = @_;
    $self->{endpoint} = '/auth/role/list';
    $self->{json_args} = '{}';
    $self->request;
    return $self;
}
1;
