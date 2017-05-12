package MojoX::Session::Store::Libmemcached;
$MojoX::Session::Store::Libmemcached::VERSION = 0.17;

use strict;
use warnings;

use base 'MojoX::Session::Store';

use Memcached::libmemcached;
use MIME::Base64;
use Storable qw/nfreeze thaw/;

__PACKAGE__->attr('servers');
__PACKAGE__->attr('_handle' => sub { Memcached::libmemcached->new });
__PACKAGE__->attr('___expiration___');

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);
    bless $self, $class;

    my $servers = ref $self->servers ?
        $self->servers : [ split(/ /, $self->servers) ];

    foreach my $server (@$servers) {
        my ($host, $port) = split(/:/, $server);

        unless ($self->_handle->memcached_server_add($host, $port)) {
            print STDERR "failed to add server $host:$port\n";
        }
    }

    return $self;
}

sub create {
    my ($self, $sid, $expires, $data) = @_;

    if ($data) {
        $data->{___expiration___} = $expires;
        $data = encode_base64(nfreeze($data));
    }

    return $self->_handle->memcached_set($sid, $data, $expires);
}

sub update {
    my ($self, $sid, $expires, $data) = @_;

    if ($data) {
        $data->{___expiration___} = $expires;
        $data = encode_base64(nfreeze($data));
    }

    return $self->_handle->memcached_replace($sid, $data, $expires);
}

sub load {
    my ($self, $sid) = @_;

    my $data_base64 = $self->_handle->memcached_get($sid);
    return unless $data_base64;

    my $data = thaw(decode_base64($data_base64));

    $self->___expiration___(delete $data->{___expiration___});

    return ($self->___expiration___, $data);
}

sub delete {
    my ($self, $sid) = @_;

    return $self->_handle->memcached_delete($sid);
}

1;
__END__

=head1 NAME

MojoX::Session::Store::Libmemcached - Memcached Store for MojoX::Session

=head1 SYNOPSIS

    my $session = MojoX::Session->new(
        store => MojoX::Session::Store::Libmemcached->new(
            servers => ['server1:11211', 'server2:11211'],
        ),
    );

    or

    # Mojolicious::Lite
    plugin 'session' => {
        servers => ['server1:11211', 'server2:11211'],
    };

    or

    # Mojolicious
    $self->plugin('session' => {
        store => [libmemcached => {
            servers => ['server1:11211', 'server2:11211'],
        }],
    });

=head1 DESCRIPTION

L<MojoX::Session::Store::Libmemcached> is a store for L<MojoX::Session> that stores a
session in Memcached.

=head1 ATTRIBUTES

L<MojoX::Session::Store::Libmemcached> implements the following attributes.

=head2 C<servers>

Array or string (separated by space) of servers, in the format host:port.

=head1 METHODS

L<MojoX::Session::Store::Libmemcached> inherits all methods from
L<MojoX::Session::Store>.

=head2 C<new>

Overload to connect to server.

=head2 C<create>

Create session.

=head2 C<update>

Update session.

=head2 C<load>

Load session.

=head2 C<delete>

Delete session.

=head1 AUTHOR

dostioffski, C<danielm@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2010, Daniel Mascarenhas.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
