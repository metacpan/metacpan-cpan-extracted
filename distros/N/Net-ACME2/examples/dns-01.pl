#!/usr/bin/env perl

package examples::dns_01;

use strict;
use warnings;

use Digest::SHA  ();
use MIME::Base64 ();

use FindBin;
use lib "$FindBin::Bin/lib";

use parent 'Net_ACME2_Example';

use constant {
    CAN_WILDCARD => 1,
};

__PACKAGE__->run() if !caller;

sub _authz_handler {
    my ($class, $acme, $authz_obj) = @_;

    my $zone = $authz_obj->identifier()->{'value'};

    my ($challenge) = grep { $_->type() eq 'dns-01' } $authz_obj->challenges();

    if (!$challenge) {
        substr($zone, 0, 0, '*.') if $authz_obj->wildcard();
        die "No DNS challenge for “$zone”!\n";
    }

    my $key_authz = $acme->make_key_authorization($challenge);

    my $sha = Digest::SHA::sha256($key_authz);
    my $b64 = MIME::Base64::encode_base64url($sha);

    print "$/Create a TXT record for:$/$/\t_acme-challenge.$zone.$/$/";
    print "… with the following value:$/$/";

    print "\t$b64$/$/";

    <STDIN>;

    return $challenge;
}

1;

