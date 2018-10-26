#
# Copyright (c) 2018 cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# Distributed under the terms of the MIT license.  See the LICENSE file for
# further details.
#
package Test::OpenStack::Client::UserAgent;

use strict;
use warnings;

sub generate {
    my ($class, %opts) = @_;

    $opts{'responses'} ||= [];

    return bless {
        'requests'  => [],
        'responses' => $opts{'responses'}
    }, $class;
}

sub new ($%) {
    shift;
}

sub request ($$) {
    my ($self, $request) = @_;

    push @{$self->{'requests'}}, $request;

    #
    # Keep tossing out responses until we get the very last one on the list,
    # so that any tests that make any requests are guaranteed to get at least
    # one response.
    #
    my $response = $self->{'responses'}->[0];

    shift @{$self->{'responses'}} if @{$self->{'responses'}} > 1;

    return $response;
}

1;
