#!/usr/bin/env perl
use strict;
use warnings;

# The matching client for examples/server.pl, driven by the same spec.
#
#   perl examples/server.pl 5000 &        # in one terminal
#   perl examples/client.pl  http://127.0.0.1:5000
#
# Open::API::Client->new(csrf => 1) makes the CSRF handshake transparent: it
# presents the expected Origin, captures the token the server sets, and echoes
# it in the X-CSRF-Token header on every state-changing call - following the
# server's single-use rotation automatically. cookie_jar => 1 carries the
# session cookie the same way a browser would.

use FindBin ();
use Open::API::Client;

my $base = shift || 'http://127.0.0.1:5000';
my $spec = "$FindBin::Bin/petstore.json";

# ---- transparent CSRF: just turn it on --------------------------------------
my $client = Open::API::Client->new(
    spec       => $spec,
    base_url   => $base,
    cookie_jar => 1,     # carry the session cookie
    csrf       => 1,     # present Origin + capture/echo the CSRF token
);

# unauthenticated: the spec requires the `session` scheme, so a protected GET
# is a 401 before we log in (this is the security check, not CSRF - GET is not
# CSRF-guarded at all).
printf "GET  /pets (anon)  -> %s (not logged in)\n",
    $client->listPets->get->{status};

# log in first: this establishes the session and the first CSRF token (the
# client captures the token behind the scenes). login is CSRF-exempt but still
# Origin-checked, so csrf => 1 is what lets it through.
my $me = $client->login(body => { username => 'alice' })->get;
printf "POST /login        -> %s (user=%s)\n", $me->{status}, $me->{data}{user};

# now authenticated: the session cookie the jar carries satisfies the security
# scheme, and $env->{'openapi.auth'} carried the user back to the handler.
my $pets = $client->listPets->get;
printf "GET  /pets         -> %s (user=%s)\n", $pets->{status}, $pets->{data}{user};

# state-changing calls now just work - no manual token wiring:
for my $pet ([1, 'rex'], [2, 'milo'], [3, 'aria']) {
    my $r = $client->createPet(body => { id => $pet->[0], name => $pet->[1] })->get;
    printf "POST /pets  (%-4s) -> %s%s\n", $pet->[1], $r->{status},
        ($r->{status} == 201 ? " ok (token rotated for next call)" : " FAILED");
}

my $del = $client->deletePet(petId => 1)->get;
printf "DELETE /pets/1     -> %s\n", $del->{status};

# ---- for contrast: a client without csrf => 1 cannot even log in ------------
my $naive = Open::API::Client->new(
    spec => $spec, base_url => $base, cookie_jar => 1);
my $blocked = $naive->login(body => { username => 'mallory' })->get;
printf "\nwithout csrf => 1 : POST /login -> %s (%s)\n",
    $blocked->{status},
    $blocked->{status} == 403 ? 'blocked at the Origin check, as expected'
                              : 'unexpected';
