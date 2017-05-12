#
# Copyright (c) 2015 cPanel, Inc.
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
            'package_ua'      => $ua,
            'package_request' => 'Test::OpenStack::Client::Request'
        );

        $test->{'test'}->($client, $ua);
    }

    return;
}

sub run_auth_tests ($@) {
    my ($class, @tests) = @_;

    foreach my $test (@tests) {
        my $endpoint    = $test->{'endpoint'}    || 'http://foo.bar/';
        my $credentials = $test->{'credentials'} || {
            'tenant'   => 'foo',
            'username' => 'foo',
            'password' => 'bar'
        };

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

        my $auth = OpenStack::Client::Auth->new($endpoint, %{$credentials},
            'package_ua'      => $ua,
            'package_request' => 'Test::OpenStack::Client::Request'
        );

        $test->{'test'}->($auth, $ua);
    }

    return;
}

1;
