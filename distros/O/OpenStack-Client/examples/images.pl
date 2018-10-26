#! /usr/bin/perl
#
# Copyright (c) 2018 cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# Distributed under the terms of the MIT license.  See the LICENSE file for
# further details.
#

use strict;
use warnings;

use OpenStack::Client::Auth ();

my $auth = OpenStack::Client::Auth->new($ENV{'OS_AUTH_URL'},
    'tenant'   => $ENV{'OS_TENANT_NAME'},
    'username' => $ENV{'OS_USERNAME'},
    'password' => $ENV{'OS_PASSWORD'}
);

my $glance = $auth->service('image');

$glance->each("/v2/images", sub {
    my ($result) = @_;

    foreach my $image (@{$result->{'images'}}) {
        $image->{'direct_url'} ||= '(unknown)';

        print "$image->{'direct_url'} $image->{'name'}\n";
    }
});
