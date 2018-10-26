#
# Copyright (c) 2018 cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# Distributed under the terms of the MIT license.  See the LICENSE file for
# further details.
#
package Test::OpenStack::Client::Request;

use strict;
use warnings;

use Test::OpenStack::Client::Message ();

our @ISA = qw(Test::OpenStack::Client::Message);

sub new ($%) {
    my ($class, $method, $path) = @_;

    die 'No HTTP method provided'       unless defined $method;
    die 'No HTTP request path provided' unless defined $path;

    return bless $class->SUPER::new(
        'method' => $method,
        'path'   => $path
    ), $class;
}

sub method ($) {
    shift->{'method'};
}

1;
