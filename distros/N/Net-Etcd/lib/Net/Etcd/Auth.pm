use utf8;
package Net::Etcd::Auth;

use strict;
use warnings;

=encoding utf8

=cut

use JSON;
use Carp;
use Types::Standard qw(Str);
use Net::Etcd::Auth::Role;

use Moo;
with 'Net::Etcd::Role::Actions';
use namespace::clean;


=head1 NAME

Net::Etcd::Auth

=cut

our $VERSION = '0.021';

=head1 DESCRIPTION

Authentication

=cut

=head1 SYNOPSIS

Steps to enable authentication.

    # add user
    $etcd->user({ name => 'root', password => 'toor' })->add;

    # add role
    $etcd->role({ name => 'root' })->add;

    # grant role
    $etcd->user_role({ user => 'root', role => 'root' })->grant;

    # enable auth
    $etcd->auth()->enable;

=cut

=head2 endpoint

=cut

has endpoint => (
    is       => 'ro',
    isa      => Str,
);

=head2 name

Defaults to $etcd->name

=cut

has name => (
    is       => 'lazy',
);

sub _build_name {
    my ($self) = @_;
    my $user = $self->etcd->name;
    return $user if $user;
    return;
}

=head2 password

Defaults to $etcd->password

=cut

has password => (
    is       => 'lazy',
);

sub _build_password {
    my ($self) = @_;
    my $pwd = $self->etcd->password;
    return $pwd if $pwd;
    return;
}

=head1 PUBLIC METHODS

=head2 authenticate

Returns token with valid authentication. The token must then be passed in the Authorization header.
The module handles passing, storing and refreshing of the token for you as long as you define a name
and password.

    # authenticate etcd as root
    $etcd = Net::Etcd->new({ name => 'root', password => 'toor' });

    # switch to non root user
    $etcd->auth({ name => $user, password => $pass })->authenticate;

=cut

sub authenticate {
    my ( $self, $options ) = @_;
    local $@;
    $self->{endpoint} = '/auth/authenticate';
    return unless ($self->password && $self->name);
    $self->request;
    my $auth;
    eval { $auth = from_json($self->{response}{content}) };
    if ($@) {
        $self->{response}{content} = 'error: ' . $@;
        return;
    }
    if ($auth && defined $auth->{token}) {
        $self->etcd->{auth_token} = $auth->{token};
    }
    return;
}

=head2 enable

Enable authentication.

    $etcd->auth()->enable;

=cut

sub enable {
    my ( $self, $options ) = @_;
    $self->{endpoint} = '/auth/enable';
    $self->{json_args} = '{}';
    $self->request;

    # init token
    $self->etcd->auth()->authenticate;
    return $self;
}

=head2 disable

Disable authentication, this requires a valid root password.

    $etcd->auth({ name => 'root', password => $pass })->disable;

=cut

sub disable {
    my ( $self, $options ) = @_;
    $self->{endpoint} = '/auth/disable';
    confess 'root name and password required for ' . __PACKAGE__ . '->disable'
      unless ($self->password && $self->name);
    $self->request;
    $self->etcd->clear_auth_token;
    return $self;
}

1;
