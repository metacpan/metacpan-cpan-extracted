#!/usr/bin/env perl

package examples::tls_alpn_01;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use parent 'Net_ACME2_Example';

use constant _CHALLENGE_TYPE => 'tls-alpn-01';

__PACKAGE__->run() if !caller;

sub _authz_handler {
    my ($class, $acme, $authz_obj) = @_;

    my $domain = $authz_obj->identifier()->{'value'};

    my $challenge = $class->_get_challenge_from_authz($authz_obj);

    my $cert_pem = $challenge->create_certificate( $acme, $domain );

    print "$/Make “$domain” serve up the following certificate:$/$/";
    print $cert_pem . $/ . $/;
    print "… over port 443 in TLS handshakes with “acme-tls/1” ALPN.$/";
    print "Then press ENTER.$/";
    <>;

    return $challenge;
}

1;
