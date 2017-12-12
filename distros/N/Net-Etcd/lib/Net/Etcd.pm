use utf8;
package Net::Etcd;
# ABSTRACT: Provide access to the etcd v3 API.

use strict;
use warnings;

use Moo;
use JSON;
use MIME::Base64;
use Net::Etcd::Auth;
use Net::Etcd::Auth::RolePermission;
use Net::Etcd::Config;
use Net::Etcd::Watch;
use Net::Etcd::Lease;
use Net::Etcd::Maintenance;
use Net::Etcd::Member;
use Net::Etcd::User;
use Types::Standard qw(Str Int Bool HashRef);

with('Net::Etcd::KV');

use namespace::clean;

=encoding utf8

=head1 NAME

Net::Etcd - etcd v3 REST API.

=cut

our $VERSION = '0.018';

=head1 SYNOPSIS

    Etcd v3.1.0 or greater is required.   To use the v3 API make sure to set environment
    variable ETCDCTL_API=3.  Precompiled binaries can be downloaded at https://github.com/coreos/etcd/releases.

    $etcd = Net::Etcd->new(); # host: 127.0.0.1 port: 2379
    $etcd = Net::Etcd->new({ host => $host, port => $port, ssl => 1 });

    # put key
    $put_key = $etcd->put({ key =>'foo1', value => 'bar' });

    # check for success of a transaction
    $put_key->is_success;

    # get single key
    $key = $etcd->range({ key =>'test0' });

    # return single key value or the first in a list.
    $key->get_value

    # get range of keys
    $range = $etcd->range({ key =>'test0', range_end => 'test100' });

    # return array { key => value } pairs from range request.
    my @users = $range->all

    # delete single key
    $etcd->deleterange({ key => 'test0' });

    # watch key range, streaming.
    $watch = $etcd->watch( { key => 'foo', range_end => 'fop'}, sub {
        my ($result) =  @_;
        print STDERR Dumper($result);
    })->create;

    # create/grant 20 second lease
    $etcd->lease( { ID => 7587821338341002662, TTL => 20 } )->grant;

    # attach lease to put
    $etcd->put( { key => 'foo2', value => 'bar2', lease => 7587821338341002662 } );

    # add new user
    $etcd->user( { name => 'samba', password => 'foo' } )->add;

    # add new user role
    $role = $etcd->role( { name => 'myrole' } )->add;

    # grant read permission for the foo key to myrole
    $etcd->role_perm( { name => 'myrole', key => 'foo', permType => 'READWRITE' } )->grant;

    # grant role
    $etcd->user_role( { user => 'samba', role => 'myrole' } )->grant;

    # defrag member's backend database
    $defrag = $etcd->maintenance()->defragment;
    print "Defrag request complete!" if $defrag->is_success;

    # member version
    $v = $etcd->version;

    # list members
    $etcd->member()->list;

=head1 DESCRIPTION

L<Net::Etcd> is object oriented interface to the v3 REST API provided by the etcd L<grpc-gateway|https://github.com/grpc-ecosystem/grpc-gateway>.

=head1 ACCESSORS

=head2 host

The etcd host. Defaults to 127.0.0.1

=cut

has host => (
    is      => 'ro',
    isa     => Str,
    default => '127.0.0.1'
);

=head2 port

Default 2379.

=cut

has port => (
    is      => 'ro',
    isa     => Int,
    default => '2379'
);

=head2 name

Username for authentication, defaults to $ENV{ETCD_CLIENT_USERNAME}

=cut

has name => (
    is  => 'ro',
    default => $ENV{ETCD_CLIENT_USERNAME}
);

=head2 password

Authentication credentials, defaults to $ENV{ETCD_CLIENT_PASSWORD}

=cut

has password => (
    is  => 'ro',
    default => $ENV{ETCD_CLIENT_PASSWORD}
);

=head2 cacert

Path to cacert, defaults to $ENV{ETCD_CERT_FILE}

=cut

has cacert => (
    is  => 'ro',
    default => $ENV{ETCD_CERT_FILE}
);

=head2 ssl

To enable set to 1

=cut

has ssl => (
    is  => 'ro',
    isa => Bool,
);

=head2 api_version

defaults to /v3alpha

=cut

has api_version => (
    is      => 'ro',
    isa     => Str,
    default => '/v3alpha'
);

=head2 api_path

The full api path. Defaults to http://127.0.0.1:2379/v3alpha

=cut

has api_path => ( is => 'lazy' );

sub _build_api_path {
    my ($self) = @_;
    return ( $self->ssl || $self->cacert ? 'https' : 'http' ) . '://'
      . $self->host . ':'. $self->port . $self->api_version;
}

=head2 auth_token

The token that is passed during authentication.  This is generated during the
authentication process and stored until no longer valid or username is changed.

=cut

has auth_token => (
    is      => 'rwp',
    clearer => 1,
);

=head1 PUBLIC METHODS

=head2 version

Returns the etcd member version

    $etcd->version()

=cut

sub version {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    my $member = Net::Etcd::Maintenance->new(
        etcd => $self,
        cb   => $cb,
        ( $options ? %$options : () ),
    );
    return $member->version;
}

=head2 watch

See L<Net::Etcd::Watch>

    $etcd->watch({ key =>'foo', range_end => 'fop' })

=cut

sub watch {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    return Net::Etcd::Watch->new(
        etcd => $self,
        cb   => $cb,
        ( $options ? %$options : () ),
    );
}

=head2 role

See L<Net::Etcd::Auth::Role>

    $etcd->role({ role => 'foo' });

=cut

sub role {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    return Net::Etcd::Auth::Role->new(
        etcd => $self,
        cb   => $cb,
        ( $options ? %$options : () ),
    );
}

=head2 role_perm

See L<Net::Etcd::Auth::RolePermission>

Grants or revoke permission of a specified key or range to a specified role.

=cut

sub role_perm {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    my $perm = Net::Etcd::Auth::RolePermission->new(
        etcd     => $self,
        cb       => $cb,
        ( $options ? %$options : () ),
    );
}

=head2 user_role

See L<Net::Etcd::User::Role>

    $etcd->user_role({ name => 'samba', role => 'foo' });

=cut

sub user_role {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    return Net::Etcd::User::Role->new(
        etcd => $self,
        cb   => $cb,
        ( $options ? %$options : () ),
    );
}

=head2 auth

See L<Net::Etcd::Auth>

    $etcd->auth({ name => 'samba', password => 'foo' })->authenticate;
    $etcd->auth()->enable;
    $etcd->auth()->disable

=cut

sub auth {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    return Net::Etcd::Auth->new(
        etcd => $self,
        cb   => $cb,
        ( $options ? %$options : () ),
    );
}

=head2 lease

See L<Net::Etcd::Lease>

    $etcd->lease( { ID => 7587821338341002662, TTL => 20 } )->grant;

=cut

sub lease {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    return Net::Etcd::Lease->new(
        etcd => $self,
        cb   => $cb,
        ( $options ? %$options : () ),
    );
}

=head2 maintenance

See L<Net::Etcd::Maintenance>

    $etcd->maintenance()->snapshot

=cut

sub maintenance {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    return Net::Etcd::Maintenance->new(
        etcd => $self,
        cb   => $cb,
        ( $options ? %$options : () ),
    );
}

=head2 member

See L<Net::Etcd::Member>

    $etcd->member()->list

=cut

sub member {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    return Net::Etcd::Member->new(
        etcd => $self,
        cb   => $cb,
        ( $options ? %$options : () ),
    );
}

=head2 user

See L<Net::Etcd::User>

    $etcd->user( { name => 'samba', password => 'foo' } )->add;

=cut

sub user {
    my ( $self, $options ) = @_;
    my $cb = pop if ref $_[-1] eq 'CODE';
    return Net::Etcd::User->new(
        etcd => $self,
        cb   => $cb,
        ( $options ? %$options : () ),
    );
}

=head2 put

See L<Net::Etcd::KV::Put>

    $etcd->put({ key =>'foo1', value => 'bar' });

=cut

=head2 deleterange

See L<Net::Etcd::KV::DeleteRange>

    $etcd->deleterange({ key=>'test0' });

=cut

=head2 range

See L<Net::Etcd::KV::Range>

    $etcd->range({ key =>'test0', range_end => 'test100' });

=cut

=head2 txn

See L<Net::Etcd::KV::Txn>

    $etcd->txn({ compare => \@compare, success => \@op });

=cut

=head2 op

See L<Net::Etcd::KV::Op>

    $etcd->op({ request_put => $put });
    $etcd->op({ request_delete_range => $range });

=cut

=head2 compare

See L<Net::Etcd::KV::Compare>

    $etcd->compare( { key => 'foo', result => 'EQUAL', target => 'VALUE', value => 'baz' });
    $etcd->compare( { key => 'foo', target => 'CREATE', result => 'NOT_EQUAL', create_revision => '2' });

=cut

=head2 configuration

Initialize configuration checks to see if etcd is installed locally.

=cut

sub configuration {
    Net::Etcd::Config->configuration;
}

=head1 AUTHOR

Sam Batschelet (hexfusion)

=head1 CONTRIBUTORS

Ananth Kavuri

=head1 ACKNOWLEDGEMENTS

The L<etcd|https://github.com/coreos/etcd> developers and community.

=head1 CAVEATS

The L<etcd|https://github.com/coreos/etcd> v3 API is in heavy development and can change at anytime please see
 L<api_reference_v3|https://github.com/coreos/etcd/blob/master/Documentation/dev-guide/api_reference_v3.md>
for latest details.

Authentication provided by this module will only work with etcd v3.3.0+

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Sam Batschelet (hexfusion).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
