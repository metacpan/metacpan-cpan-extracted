#
# Copyright (c) 2018 cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# Distributed under the terms of the MIT license.  See the LICENSE file for
# further details.
#
package OpenStack::Client::Auth::v2;

use strict;
use warnings;

use OpenStack::Client ();

sub new ($$%) {
    my ($class, $endpoint, %args) = @_;

    die 'No OpenStack tenant name provided in "tenant"' unless defined $args{'tenant'};
    die 'No OpenStack username provided in "username"'  unless defined $args{'username'};
    die 'No OpenStack password provided in "password"'  unless defined $args{'password'};

    my $client = OpenStack::Client->new($endpoint,
        'package_ua'       => $args{'package_ua'},
        'package_request'  => $args{'package_request'},
        'package_response' => $args{'package_response'}
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
        die 'No token found in response';
    }

    return bless {
        'package_ua'       => $args{'package_ua'},
        'package_request'  => $args{'package_request'},
        'package_response' => $args{'package_response'},
        'response'         => $response,
        'clients'          => {},
        'services'         => $response->{'access'}->{'serviceCatalog'}
    }, $class;
}

sub response ($) {
    shift->{'response'};
}

sub access ($) {
    shift->{'response'}->{'access'};
}

sub token ($) {
    shift->{'response'}->{'access'}->{'token'}->{'id'};
}

sub services ($) {
    my ($self) = @_;

    my %types = map {
        $_->{'type'} => 1
    } @{$self->{'services'}};

    return sort keys %types;
}

sub service ($$%) {
    my ($self, $type, %opts) = @_;

    if (defined $self->{'clients'}->{$type}) {
        return  $self->{'clients'}->{$type};
    }

    if (defined $opts{'uri'}) {
        return $self->{'clients'}->{$type} = OpenStack::Client->new($opts{'uri'},
            'package_ua'       => $self->{'package_ua'},
            'package_request'  => $self->{'package_request'},
            'package_response' => $self->{'package_response'},
            'token'            => $self->token
        );
    }

    $opts{'endpoint'} ||= 'public';

    if ($opts{'endpoint'} !~ /^(?:public|internal|admin)$/) {
        die 'Invalid endpoint type specified in "endpoint"';
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
                'package_ua'       => $self->{'package_ua'},
                'package_request'  => $self->{'package_request'},
                'package_response' => $self->{'package_response'},
                'token'            => $self->token
            );
        }
    }

    die "No service type '$type' found";
}

1;
