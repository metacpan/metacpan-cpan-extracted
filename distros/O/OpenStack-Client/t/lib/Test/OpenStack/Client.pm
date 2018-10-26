#
# Copyright (c) 2018 cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# Distributed under the terms of the MIT license.  See the LICENSE file for
# further details.
#
package Test::OpenStack::Client;

use strict;
use warnings;

use Test::OpenStack::Client::Request   ();
use Test::OpenStack::Client::Response  ();
use Test::OpenStack::Client::UserAgent ();

sub run_client_tests ($@) {
    my ($class, @tests) = @_;

    foreach my $test (@tests) {
        my $endpoint = $test->{'endpoint'} || 'http://foo.bar/';

        my @responses;

        push @responses, map {
            Test::OpenStack::Client::Response->new(%{$_})
        } @{$test->{'responses'}} if defined $test->{'responses'};

        unless (@responses) {
            push @responses, Test::OpenStack::Client::Response->new;
        }

        my $ua = Test::OpenStack::Client::UserAgent->generate(
            'responses' => \@responses
        );

        my $client = OpenStack::Client->new($endpoint,
            'package_ua'       => $ua,
            'package_request'  => 'Test::OpenStack::Client::Request',
            'package_response' => 'Test::OpenStack::Client::Response'
        );

        $test->{'test'}->($client, $ua);
    }

    return;
}

sub run_auth_tests ($@) {
    my ($class, %args) = @_;

    my $endpoint    = 'http://foo.bar/';
    my $credentials = {
        'tenant'   => 'foo',
        'username' => 'foo',
        'password' => 'bar'
    };

    foreach my $test (@{$args{'tests'}}) {
        my $ua = Test::OpenStack::Client::UserAgent->generate(
            'responses' => [Test::OpenStack::Client::Response->new(
                'headers' => $args{'headers'},
                'content' => $args{'content'}
            )]
        );

        my $auth = OpenStack::Client::Auth->new($endpoint, %{$credentials},
            'version'          => $args{'version'},
            'package_ua'       => $ua,
            'package_request'  => 'Test::OpenStack::Client::Request',
            'package_response' => 'Test::OpenStack::Client::Response'
        );

        $test->($auth, $ua);
    }

    return;
}

1;
