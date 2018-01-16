#!/usr/bin/env perl

package examples::http_01;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use parent 'Net_ACME2_Example';

__PACKAGE__->run() if !caller;

sub _authz_handler {
    my ($class, $acme, $authz_obj) = @_;

    my $domain = $authz_obj->identifier()->{'value'};

    my ($http_challenge) = grep { $_->type() eq 'http-01' } $authz_obj->challenges();

    if (!$http_challenge) {
        die "No HTTP challenge for “$domain”!\n";
    }

    my $uri_to_be_loaded = "http://$domain" . $http_challenge->path();
    my $key_authz = $acme->make_key_authorization($http_challenge);

    print "$/Please make the contents of this path:$/\t$uri_to_be_loaded$/$/";
    print "… serve up the following contents:$/$/\t$key_authz$/$/";
    print "Then press ENTER.$/";
    <>;

    return $http_challenge;
}

1;
