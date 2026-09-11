#!/usr/bin/env perl
#
# Serve this application over https on localhost:5000.
#
# https is not decoration here. The identity provider answers with a
# cross-site POST, so the cookie carrying the login must be
# SameSite=None, and a browser drops a SameSite=None cookie that is not
# Secure. The plugin refuses to boot over plain http rather than let
# every login fail at the assertion consumer with nothing in the log.
#
#   perl server.pl
#
# The certificate in ../certs is self-signed, so a browser will warn
# once. Accept it, or the POST back from the provider will not arrive.
use strict;
use warnings;
use lib 'lib';
use Hyperman;
use SSODemo;

die "Hyperman was built without TLS; see Hyperman->has_tls\n"
    unless Hyperman->has_tls;

my $app = SSODemo->to_app;

print "SSODemo on https://localhost:5000/\n";
print "the demo identity provider belongs on http://localhost:5001/\n";

Hyperman->run(
    app      => $app,
    port     => 5000,
    workers  => 1,
    tls_cert => '../certs/sp-tls-cert.pem',
    tls_key  => '../certs/sp-tls-key.pem',
);
