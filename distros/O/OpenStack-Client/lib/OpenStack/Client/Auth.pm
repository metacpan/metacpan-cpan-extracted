#
# Copyright (c) 2015 cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# Distributed under the terms of the MIT license.  See the LICENSE file for
# further details.
#
package OpenStack::Client::Auth;

use strict;
use warnings;

use OpenStack::Client ();

=encoding utf8

=head1 NAME

OpenStack::Client::Auth - OpenStack Keystone authentication and authorization

=head1 SYNOPSIS

    use OpenStack::Client::Auth ();

    my $auth = OpenStack::Client::Auth->new('http://openstack.foo.bar:5000/v2.0',
        'tenant'   => $ENV{'OS_TENANT_NAME'},
        'username' => $ENV{'OS_USERNAME'},
        'password' => $ENV{'OS_PASSWORD'}
    );

    my $glance = $auth->service('image',
        'region' => $ENV{'OS_REGION_NAME'}
    );

=head1 DESCRIPTION

C<OpenStack::Client::Auth> provides an interface for obtaining authorization
to access other OpenStack cloud services.

=head1 AUTHORIZING WITH KEYSTONE

=over

=item C<OpenStack::Client::Auth-E<gt>new(I<$endpoint>, I<%args>)>

Contact the OpenStack Keystone API at the address provided in I<$endpoint>, and
obtain an authorization token and set of endpoints for which the client is
allowed to access.  Credentials are specified in I<%args>; the following named
values are required:

=over

=item * B<tenant>

The OpenStack tenant (project) name

=item * B<username>

The OpenStack user name

=item * B<password>

The OpenStack password

=back

When successful, this method will return an object containing the following:

=over

=item * response

The full decoded JSON authorization response from Keystone

=item * services

A hash containing services the client has authorization to

=item * clients

An initially empty hash that would contain L<OpenStack::Client> objects obtained
for any requested OpenStack services

=back

=cut

sub new ($$%) {
    my ($class, $endpoint, %args) = @_;

    die('No OpenStack authentication endpoint provided') unless defined $endpoint;
    die('No OpenStack tenant name provided in "tenant"') unless defined $args{'tenant'};
    die('No OpenStack username provided in "username"')  unless defined $args{'username'};
    die('No OpenStack password provided in "password"')  unless defined $args{'password'};

    my $client = OpenStack::Client->new($endpoint,
        'package_ua'      => $args{'package_ua'},
        'package_request' => $args{'package_request'}
    );

    my $response = $client->call('POST' => '/tokens', {
        'auth' => {
            'tenantName'          => $args{'tenant'},
            'passwordCredentials' => {
                'username' => $args{'username'},
                'password' => $args{'password'}
            }
        }
    });

    unless (defined $response->{'access'}->{'token'}->{'id'}) {
        die('No token found in response');
    }

    return bless {
        'package_ua'      => $args{'package_ua'},
        'package_request' => $args{'package_request'},
        'response'        => $response,
        'clients'         => {},
        'services'        => $response->{'access'}->{'serviceCatalog'}
    }, $class;
}

=back

=head1 RETRIEVING RESPONSE

=over

=item C<$auth-E<gt>response()>

Return the full decoded response from the Keystone API.

=cut

sub response ($) {
    shift->{'response'};
}

=back

=head1 ACCESSING AUTHORIZATION DATA

=over

=item C<$auth-E<gt>access()>

Return the service access data stored in the current object.

=cut

sub access ($) {
    shift->{'response'}->{'access'};
}

=back

=head1 ACCESSING TOKEN DATA

=over

=item C<$auth-E<gt>token()>

Return the authorization token data stored in the current object.

=cut

sub token ($) {
    shift->{'response'}->{'access'}->{'token'};
}

=back

=head1 OBTAINING LIST OF SERVICES AUTHORIZED

=over

=item C<$auth-E<gt>services()>

Return a list of service types the OpenStack user is authorized to access.

=cut

sub services ($) {
    my ($self) = @_;

    my %types = map {
        $_->{'type'} => 1
    } @{$self->{'services'}};

    return sort keys %types;
}

=back

=head1 ACCESSING SERVICES AUTHORIZED

=over

=item C<$auth-E<gt>service(I<$type>, I<%opts>)>

Obtain a client to the OpenStack service I<$type>, where I<$type> is usually
one of:

=over

=item * B<compute>

=item * B<ec2>

=item * B<identity>

=item * B<image>

=item * B<network>

=item * B<volumev2>

=back

The following values may be specified in I<%opts> to help locate the most
appropriate endpoint for a given service:

=over

=item * B<uri>

When specified, use a specific URI to gain access to a named service endpoint.
This might be useful for non-production development or testing scenarios.

=item * B<id>

When specified, attempt to obtain a client for the very endpoint indicated by
that identifier.

=item * B<region>

When specified, attempt to obtain a client for the endpoint for that region.
When not specified, the a client for the first endpoint found for service
I<$type> is returned instead.

=item * B<endpoint>

When specified and set to one of 'public', 'internal' or 'admin', return a
client for the corresponding public, internal or admin endpoint.  The default
endpoint is the public endpoint.

=item * B<internal>

When specified (and set to 1), a client is opened for the internal endpoint
corresponding to service I<$type>.

=item * B<admin>

When specified (and set to 1), a client is opened for the administrative
endpoint corresponding to service I<$type>.

=back

=cut

sub service ($$%) {
    my ($self, $type, %opts) = @_;

    if (defined $self->{'clients'}->{$type}) {
        return  $self->{'clients'}->{$type};
    }

    if (defined $opts{'uri'}) {
        return $self->{'clients'}->{$type} = OpenStack::Client->new($opts{'uri'},
            'package_ua'      => $self->{'package_ua'},
            'package_request' => $self->{'package_request'},
            'token'           => $self->token
        );
    }

    $opts{'endpoint'} ||= 'public';

    if ($opts{'endpoint'} !~ /^(?:public|internal|admin)$/) {
        die('Invalid endpoint type specified in "endpoint"');
    }

    foreach my $service (@{$self->{'services'}}) {
        next unless $type eq $service->{'type'};

        my $uri;

        foreach my $endpoint (@{$service->{'endpoints'}}) {
            next if defined $opts{'id'}     && $endpoint->{'id'}     ne $opts{'id'};
            next if defined $opts{'region'} && $endpoint->{'region'} ne $opts{'region'};

            if ($opts{'endpoint'} eq 'public') {
                $uri = $endpoint->{'publicURL'};
            } elsif ($opts{'endpoint'} eq 'internal') {
                $uri = $endpoint->{'internalURL'};
            } elsif ($opts{'endpoint'} eq 'admin') {
                $uri = $endpoint->{'adminURL'};
            }

            return $self->{'clients'}->{$type} = OpenStack::Client->new($uri,
                'package_ua'      => $self->{'package_ua'},
                'package_request' => $self->{'package_request'},
                'token'           => $self->token
            );
        }
    }

    die("No service type '$type' found");
}

=back

=head1 AUTHOR

Written by Alexandra Hrefna Hilmisdóttir <xan@cpanel.net>

=head1 COPYRIGHT

Copyright (c) 2015 cPanel, Inc.  Released under the terms of the MIT license.
See LICENSE for further details.

=cut

1;
