use strict;
use warnings;

use blib;

use Net::mbedTLS;
use IO::Socket::INET;

use constant PEM => <<END;
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAr06s0p/WoEiLflNCnZ+dyRyMPk2U3ewmR8qQlAF3bZ72mUnq
tqtLlbbJS+8I+l3PHBBbiV9+a9ICPkWju9Yk4e3EGFl2uKllSJHTafrz7lnlVXfb
AXMarUjc1uQiAPs+oY0nxhruaHWyBixHKMETtflvY25j6HPMpxV8+kDZNbkcs/k/
8wGCTFG5SOv0xLO2YiCKc3p78N6JIfVloOB4UVSbiEAjiWP1zzZIMyhnTXjvDkKR
qNoLxV1osXPq+OZv7PUgskxc36/+ez8ZnLdl1ctH+lvP27GSF51d3um/QrI5P7Ap
zdDvXoDuV0xoYwkFKL9xU55twg/AsCG1XN53UQIDAQABAoIBAATOukgTaJIgMy0d
cOn8LtpNTV5HB+JXH8yftjvM137a2WXmREjKpUm/h8Eslrkw+eVJ4IzBoOipi3S0
ObOEwaGtgM9vIqWZRaUKFLtnDan3bqXbodamFrDyWtYMzw7qVPMeuRzCb8/PDHkF
XVU1iEoZA1A9foFpLY9WdEUzopFJzOvBkUSn+PB18l1EM4kEEu8QBRywCkIqRXOp
WA5ARWMLDS9p+27/06AEElI/bQLpLdizIS9MheuJTi8xZwYx4Lk1V1koetSAlcVv
X2j5jXRp7u/dvAWYBooPt07dGOSGI00WCw78C+xp5x5O/kS90IUwFn/64/mDyyPw
AhSpF1ECgYEA2GWaD0bT5tpx3luY7IEadT+lHwGa9YFQGSMJAnVhcQcdfmaA33oE
9h7h/YB8ERS+ZhZow+9OavgjDnhssWYLhSpPDWNm4dn5WAHyF7kOQlwM7IhndE1n
T4/Xv0ivuMnrAFe1oiLMv6v+uaLp/ntX+zFF12zhTMEhUo1LQ1g5uQkCgYEAz2P9
HejuGd6ku2HCctBQS/ntz0P8YHtf6gprPBeda3OaU4NdpSKrk/23oZOM7XHbAqEJ
gHYbLSHOGjI//enB5RYJvViJHCjxnfXO70Bb1uIh32iZrM588xJ408/2wdWJrXYV
pOZc+ZyGwmbz1XMFgQvK+pKbqXl37wv9lABqxgkCgYEArUpf3w/3LY2NVmW/xtV0
XKSFFJlygFv3ysl1s5RQXfU2tzxaw5uxUW9Vxm4X7I3SE2qqpw2CnMLtP+9MC5wO
aauB9tS9VOv7c3DLcBfvxVB1wQ1S254It3wXZ8VLgw2ftXyHpbl8gZm4uOwvum0H
/c5tgaBdo9udVcB0nw+N2hECgYEAt7ugynfLQbYDAVNZnrg4+yZ/7ekQVTXYQpNa
b5GIUGLJbYVrWFp/4YucvRPofZAp9IlQzrNT3kcdvg2Yrc4Djn5YwJwIVJ9dd5EG
9OVyt8v9MF0OEI+bGQnba+PJe+4/nCKKiF3iLu3iYaYuDYNqc+pLuHRcXeeUPn7D
9/PqpGkCgYBk3EQyp5l8UZMazJfhY+nhdiDa5DtyJKE2lIun6WaaA1rXiarzO9dP
sxd2CWi4t32hONPag3VHDoA8l9jCT2vKvf0uhF/u2rkrWNrx6zVFJP9dt5iPyaGS
A6rybpESIytSPFmWM7QQ1A2Jkid3sgTtOWaTU7eJxyCLXCPVr9+r/A==
-----END RSA PRIVATE KEY-----
-----BEGIN CERTIFICATE-----
MIIDATCCAemgAwIBAgIHAWOEc2BChTANBgkqhkiG9w0BAQsFADAmMSQwIgYDVQQK
Ext0ZXN0c3NsLnNpdGUgLSBpbnRlcm1lZGlhdGUwHhcNMTgwMTAxMDAwMDAwWhcN
MjIxMjAyMTkzMzAwWjAWMRQwEgYDVQQDEwtleGFtcGxlLmNvbTCCASIwDQYJKoZI
hvcNAQEBBQADggEPADCCAQoCggEBAK9OrNKf1qBIi35TQp2fnckcjD5NlN3sJkfK
kJQBd22e9plJ6rarS5W2yUvvCPpdzxwQW4lffmvSAj5Fo7vWJOHtxBhZdripZUiR
02n68+5Z5VV32wFzGq1I3NbkIgD7PqGNJ8Ya7mh1sgYsRyjBE7X5b2NuY+hzzKcV
fPpA2TW5HLP5P/MBgkxRuUjr9MSztmIginN6e/DeiSH1ZaDgeFFUm4hAI4lj9c82
SDMoZ0147w5CkajaC8VdaLFz6vjmb+z1ILJMXN+v/ns/GZy3ZdXLR/pbz9uxkhed
Xd7pv0KyOT+wKc3Q716A7ldMaGMJBSi/cVOebcIPwLAhtVzed1ECAwEAAaNEMEIw
EwYDVR0gBAwwCjAIBgZngQwBAgEwFgYDVR0RBA8wDYILZXhhbXBsZS5jb20wEwYD
VR0lBAwwCgYIKwYBBQUHAwEwDQYJKoZIhvcNAQELBQADggEBAGDmTKxkuUGxMIRJ
dnsEmAnwT8yqJt/W4ftzRYuYw4Fpt0EvlSBwUA/+cy5yrQc2fLWYF0DaOUXqKPoh
6jzlRMV981HLrEfPaxsMLm4hxwTC+5L0HuxBqy75paLvUXTQCyS5v7rZtx8VSI8W
HUYFDRo0FVj3F777lVp4o1stbCYxbM0+LL2onUXEUl5Nggfnx/sZu6jsKO7USTBw
SIAUuAGTwmAzMkD8hVLJoMyJILNvNAvI5Hx47iCh/an1RNJBfsKbh2OkvM36duZy
cd6elrvhYK4S6jcgx2pkFYNBDkMdE5B4xdWQTWM4AGyq1deIHz005AvJHexxptGU
sZY/+K0=
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIC3DCCAcSgAwIBAgIBAjANBgkqhkiG9w0BAQUFADAeMRwwGgYDVQQKExN0ZXN0
c3NsLnNpdGUgLSByb290MB4XDTE4MDEwMTAwMDAwMFoXDTI5MTIzMTIzNTk1OVow
JjEkMCIGA1UEChMbdGVzdHNzbC5zaXRlIC0gaW50ZXJtZWRpYXRlMIIBIjANBgkq
hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxm0ITp8Ztoegv+2Yyiguit0rTv6Nz3YR
H6aTXWer/DEz3Pba4lFZr7kmg9yZpKC0Zgz3/UZBZumJZbjvq8A6tLeOjFFspazi
X4yrEIt8Yzt/oIuZjSawoQFpHGP6THN+By6eRpcSaNM1bd7bKF1oYEbqSaL97Bqx
aepaFkHws0RoOmdBhZZgz9LPch9QtkuUq/n3OAB39x2ejCWe2nx6hC7vZdqhPde2
K0jW0HzDNhVnzCidHZxHD6GhuGGeV0u9hD0diCF5BV20tCNVF4RyEkXj+xFPgJB2
prwtGPbRIiVVhfac/1U1ba1RnNfth5bnPqirIvk0p2oXSvpNANnvtQIDAQABox0w
GzAMBgNVHRMEBTADAQH/MAsGA1UdDwQEAwIC9DANBgkqhkiG9w0BAQUFAAOCAQEA
XAeBplouyhcY4rLrk6a5biBWAv2lfFK3moDHp9iuBEiqnaDvrQB11YhrsrA+U/uf
4M7+RzPg+UqAWuYqaDH6wkXjh6/LTpZq9Td9kO1LWOS9ttMe2uoHecSuX9AnXDJz
Q+3l8RLIa8MP4HrDvC0l1vrE7V/QcjjKzcrwGk0MHfwFKwf2Men4N4MGxfLrJeuU
aWNjouYeWtB9VB3f7kCbi+1iSQabo949RK5KEsJ15Mc+2MOKrvvPvchAJLDJ7z4o
cDYPwTfSE9Ly7P3/pkd3QGmXrfJ3ZGqtEX7eB9xcwyDZq2N4UZmrFGeiRIt47j1O
Y+yHmkRiS81s7z+6Wqo/gA==
-----END CERTIFICATE-----
END

my $tls = Net::mbedTLS->new();

my $socket = IO::Socket::INET->new(
    Listen => 1,
    LocalAddr => "localhost:0",
) or die;

printf "Listening on port %d; do:\n", $socket->sockport();
printf "openssl s_client -debug -connect localhost:%d\n", $socket->sockport();

my $peer = $socket->accept();

printf "Got connection!\n";

my $tlsserver = $tls->create_server(
    $peer,

    key_and_certs => [ PEM ],

    servername_cb => sub {
        my $obj = shift;

        $obj->set_own_key_and_certs(PEM);

        return;
    },
);

print "Made server; now type something into OpenSSL …\n";

my $output = "\0" x 100;
my $got = $tlsserver->read($output);

print substr($output, 0, $got);

$tlsserver->close_notify();
