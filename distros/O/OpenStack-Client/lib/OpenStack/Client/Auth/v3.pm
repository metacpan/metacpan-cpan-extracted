#
# Copyright (c) 2019 cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# Distributed under the terms of the MIT license.  See the LICENSE file for
# further details.
#
package OpenStack::Client::Auth::v3;

use strict;
use warnings;

use OpenStack::Client ();

sub new ($$%) {
    my ($class, $endpoint, %args) = @_;

    die 'No OpenStack username provided in "username"'  unless defined $args{'username'};
    die 'No OpenStack password provided in "password"'  unless defined $args{'password'};

    $args{'domain'} ||= 'default';

    my $client = OpenStack::Client->new($endpoint,
        'package_ua'       => $args{'package_ua'},
        'package_request'  => $args{'package_request'},
        'package_response' => $args{'package_response'}
    );

    my %request = (
        'auth' => {
            'identity' => {
                'methods'  => [qw(password)],
                'password' => {
                    'user' => {
                        'name'     => $args{'username'},
                        'password' => $args{'password'},
                        'domain'   => {
                            'name' => $args{'domain'}
                        }
                    }
                }
            }
        }
    );

    $request{'auth'}->{'scope'} = $args{'scope'} if defined $args{'scope'};

    my $response = $client->request(
        'method' => 'POST',
        'path'   => '/auth/tokens',
        'body'   => \%request
    );

    my $body = $response->decode_json;

    unless (defined $response->header('X-Subject-Token')) {
        die 'No token found in response headers';
    }

    unless (defined $body->{'token'}) {
        die 'No token found in response body';
    }

    unless (defined $body->{'token'}->{'catalog'}) {
        die 'No service catalog found in response body token';
    }

    return bless {
        'package_ua'       => $args{'package_ua'},
        'package_request'  => $args{'package_request'},
        'package_response' => $args{'package_response'},
        'response'         => $response,
        'body'             => $body,
        'clients'          => {},
        'services'         => $body->{'token'}->{'catalog'}
    }, $class;
}

sub body ($) {
    shift->{'body'};
}

sub response ($) {
    shift->{'response'};
}

sub access ($) {
    shift->{'body'}->{'access'};
}

sub token ($) {
    shift->{'response'}->header('X-Subject-Token');
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

        foreach my $endpoint (@{$service->{'endpoints'}}) {
            next if defined $opts{'id'}       && $endpoint->{'id'}        ne $opts{'id'};
            next if defined $opts{'region'}   && $endpoint->{'region'}    ne $opts{'region'};
            next if defined $opts{'endpoint'} && $endpoint->{'interface'} ne $opts{'endpoint'};

            return $self->{'clients'}->{$type} = OpenStack::Client->new($endpoint->{'url'},
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
