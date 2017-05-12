#
# Copyright (c) 2015 cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# Distributed under the terms of the MIT license.  See the LICENSE file for
# further details.
#
package Test::OpenStack::Client::Response;

use strict;
use warnings;

use Test::OpenStack::Client::Message ();

our @ISA = qw(Test::OpenStack::Client::Message);

sub new ($%) {
    my ($class, %opts) = @_;

    $opts{'code'} ||= 200;

    return bless $class->SUPER::new(%opts), $class;
}

sub code ($) {
    shift->{'code'};
}

1;
