#!/usr/bin/env perl

use strict;
use warnings;

use OpenStack::MetaAPI ();

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::OpenStack::MetaAPI qw{:all};
use Test::OpenStack::MetaAPI::Auth qw{:all};

use JSON;

mock_lwp_useragent();

# Stands in for an auth object somebody else built.  It only has to satisfy the
# 'services' the api delegates, and to be a blessed object, which is what tells
# BUILDARGS this is an auth object rather than an endpoint URL or a config hash.
{

    package Test::PrebuiltAuth;

    sub new { return bless {}, shift }
    sub services { return qw{fake} }
}

like(
    dies { OpenStack::MetaAPI->new() },
    qr/Missing arguments to create Auth object/,
    "Missing arguments to create Auth object");

{
    #local $Test::OpenStack::MetaAPI::UA_DISPLAY_OUTPUT = 1;
    my $api = get_api_object();

    is ref $api->auth, "OpenStack::Client::Auth::v3",
      "OpenStack::Client::Auth::v3";
    is $api->auth->token, "custom-token",
      "auth is aware of the token from headers";

    is [$api->services], [
        'compute',
        'identity',
        'image',
        'network',
        'placement',
        'volume',
        'volumev2',
        'volumev3'
      ],
      "list os services from auth object";
}

# An auth object that is handed over is the one that gets used.
#
# Nothing is mocked for this on purpose: constructing an OpenStack::Client::Auth
# would POST to Keystone and die on the username it was not given, so reaching
# the assertions at all is the evidence that no second auth object was built.
{
    my $api = OpenStack::MetaAPI->new({auth => Test::PrebuiltAuth->new, debug => 1});

    is ref $api->auth, 'Test::PrebuiltAuth',
      "the auth object we passed is the one used";
    is [$api->services], ['fake'], "delegated calls reach it";
    ok $api->debug, "the rest of the arguments survive alongside it";
}

# ... and a bare hashref with no auth in it is still not enough to build one.
like(
    dies { OpenStack::MetaAPI->new({debug => 1}) },
    qr/No OpenStack tenant name provided/,
    "a hashref without an auth object still goes through OpenStack::Client::Auth");

# A clouds.yaml cloud entry is a plain hashref whose 'auth' is itself an
# unblessed hash (auth_url, username, password, ...).  That must not be
# mistaken for a prebuilt auth object: it has to fall through and build a real
# OpenStack::Client::Auth, which dies on the details it was not given.
like(
    dies { OpenStack::MetaAPI->new({auth => {username => 'x'}}) },
    qr/No OpenStack tenant name provided/,
    "a clouds.yaml-shaped hash with an unblessed auth is not taken as the auth object");

done_testing;
