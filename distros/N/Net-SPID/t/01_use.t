#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok('Net::SPID');
}

{
    my $spid = Net::SPID->new(
        sp_entityid     => 'https://www.prova.it/',
        sp_key_file     => 'sp.key',
        sp_cert_file    => 'sp.pem',
        sp_assertionconsumerservice => [
            'http://localhost:3000/spid-sso',
        ],
        sp_singlelogoutservice => {
            'http://localhost:3000/spid-slo' => 'HTTP-Redirect',
        },
    );
    isa_ok($spid, 'Net::SPID::SAML');
}

__END__
