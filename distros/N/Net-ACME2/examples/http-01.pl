#!/usr/bin/env perl

package examples::http_01;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use parent 'Net_ACME2_Example';

use constant _CHALLENGE_TYPE => 'http-01';

__PACKAGE__->run() if !caller;

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
