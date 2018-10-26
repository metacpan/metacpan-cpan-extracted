#
# Copyright (c) 2018 cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# Distributed under the terms of the MIT license.  See the LICENSE file for
# further details.
#
package Test::OpenStack::Client::Response;

use strict;
use warnings;

use base qw(Test::OpenStack::Client::Message OpenStack::Client::Response);

sub new ($%) {
    my ($class, %opts) = @_;

    $opts{'code'} ||= 200;

    return bless $class->SUPER::new(%opts), $class;
}

sub code ($) {
    shift->{'code'};
}

1;
