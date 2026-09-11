#!/usr/bin/env perl
#
# Start both halves of the SAML example.
#
#   perl run.pl
#
#   https://localhost:5000/   SSODemo, the service provider
#   http://localhost:5001/    the demo identity provider
#
# Then open the first one and click "Sign in with example".
#
# Ctrl-C stops both.
#
# WHY TWO PROCESSES AND WHY ONE OF THEM IS https
#
# A SAML login is a conversation between two servers through a browser.
# The service provider redirects to the provider; the provider signs an
# assertion and POSTs it back. That POST arrives from the provider's
# origin, so it is cross-site, and a cookie with SameSite=Lax is not sent
# on a cross-site POST - which is why the plugin keeps its flow record in
# a cookie of its own with SameSite=None, and why that cookie needs
# Secure, and why the service provider needs https. Punk::Plugin::SAML
# refuses to boot over plain http rather than let every login fail at the
# assertion consumer with nothing in the log to say why.
#
# The certificate in certs/ is self-signed, so the browser will warn once
# on https://localhost:5000. Accept it: if you do not, the POST back from
# the provider never arrives and the login looks like it silently failed.
use strict;
use warnings;
use FindBin ();
use POSIX ();

chdir $FindBin::Bin or die "cannot chdir to $FindBin::Bin: $!\n";

for my $f ('certs/sp-tls-cert.pem', 'certs/sp-tls-key.pem',
           'certs/idp-cert.pem',    'certs/idp-key.pem') {
    -r $f or die <<"MISSING";
$f is missing.

The demo certificates are generated once. From this directory:

  mkdir -p certs
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \\
      -subj "/CN=demo-idp" \\
      -keyout certs/idp-key.pem -out certs/idp-cert.pem
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \\
      -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" \\
      -keyout certs/sp-tls-key.pem -out certs/sp-tls-cert.pem
MISSING
}

require Hyperman;
Hyperman->has_tls
    or die "This Hyperman was built without TLS, so the service provider "
         . "cannot be served over https.\nSee Hyperman->has_tls and the "
         . "OpenSSL build notes in perldoc Hyperman.\n";

$| = 1;

# ---- the identity provider, in a child --------------------------------

my $idp = fork;
defined $idp or die "fork: $!\n";

unless ($idp) {
    # In the child. chdir into the provider so its own config and its
    # ../certs paths resolve the way they do when it is run on its own.
    chdir 'IdP' or die "cannot chdir to IdP: $!\n";
    unshift @INC, 'lib';
    require SSODemoIdP;
    my $app = SSODemoIdP->to_app;
    print "identity provider  http://localhost:5001/\n";
    Hyperman->run(app => $app, port => 5001, workers => 1);

    # Never reached while the server runs. If it ever is, leave through
    # POSIX::_exit so this child does not run the parent's END blocks or
    # destructors a second time.
    POSIX::_exit(0);
}

# ---- the service provider, here ---------------------------------------

# The child is only useful while this process lives, and a stray server
# on 5001 is a confusing thing to leave behind.
my $reaped = 0;
sub stop_idp {
    return if $reaped++;
    kill 'TERM', $idp;
    waitpid $idp, 0;
}
$SIG{INT} = $SIG{TERM} = sub { stop_idp(); POSIX::_exit(0) };
END { stop_idp() if $idp }

# Wait for the provider to be listening before compiling the service
# provider: its `saml_idp` resolves the metadata at boot, and a fetch
# that fails is a croak. That is the right behaviour - an application
# whose only login is SAML should not start without its provider - but
# here it just means the two started in the wrong order.
{
    require IO::Socket::INET;
    my $up = 0;
    for (1 .. 100) {
        my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1",
                                      PeerPort => 5001, Timeout => 1);
        if ($s) { close $s; $up = 1; last }
        select undef, undef, undef, 0.1;
    }
    unless ($up) {
        stop_idp();
        die "the demo identity provider did not come up on 5001\n";
    }
}

chdir 'SSO' or die "cannot chdir to SSO: $!\n";
unshift @INC, 'lib';
require SSODemo;
my $app = SSODemo->to_app;

print "service provider   https://localhost:5000/\n";
print "\nOpen https://localhost:5000/ and accept the certificate warning.\n";
print "Ctrl-C stops both.\n\n";

Hyperman->run(
    app      => $app,
    port     => 5000,
    workers  => 1,
    tls_cert => '../certs/sp-tls-cert.pem',
    tls_key  => '../certs/sp-tls-key.pem',
);

stop_idp();
