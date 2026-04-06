#!/usr/bin/env perl

package Net_ACME2_Example_HTTP01;

use strict;
use warnings;

use constant _CHALLENGE_TYPE => 'http-01';

sub _authz_handler {
    my ($class, $acme, $authz_obj) = @_;

    my $domain = $authz_obj->identifier()->{'value'};

    my $http_challenge = $class->_get_challenge_from_authz($authz_obj);

    my $uri_to_be_loaded = "http://$domain" . $http_challenge->get_path();
    my $content = $http_challenge->get_content($acme);

    print "$/Make the contents of this path:$/\t$uri_to_be_loaded$/$/";
    print "… serve up the following contents:$/$/\t$content$/$/";
    print "Then press ENTER.$/";
    <>;

    return $http_challenge;
}

1;
