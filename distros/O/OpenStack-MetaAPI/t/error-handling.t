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

my $api = get_api_object(use_env => 0);

ok $api, "got one api object" or die;

# --- image_from_uid error paths ---

{
    note "image_from_uid: dies with descriptive message when uid is undef";

    like dies { $api->image_from_uid(undef) },
      qr/image_from_uid: uid is required/,
      "image_from_uid(undef) gives useful error message";
}

# --- image_from_name error paths ---

{
    note "image_from_name: dies with descriptive message when name is undef";

    like dies { $api->image_from_name(undef) },
      qr/image_from_name: name is required/,
      "image_from_name(undef) gives useful error message";
}

# --- images() is not exposed as a top-level route ---
# (The Images service blocks it internally, but it's not routed through MetaAPI)

# --- create_vm required argument validation ---

{
    note "create_vm: dies with descriptive messages for missing arguments";

    like dies { $api->create_vm() },
      qr/'flavor' name or id is required/,
      "create_vm() without flavor gives useful error";

    like dies { $api->create_vm(flavor => 'small') },
      qr/'network' name or id is required/,
      "create_vm() without network gives useful error";

    like dies { $api->create_vm(flavor => 'small', network => 'net1') },
      qr/'image' name or id is required/,
      "create_vm() without image gives useful error";

    like dies {
        $api->create_vm(
            flavor  => 'small',
            network => 'net1',
            image   => 'img1')
    },
      qr/'name' field is required/,
      "create_vm() without name gives useful error";

    # 'network_for_floating_ip' is deliberately NOT checked here: it is an
    # optional argument.  A cloud whose only network is external and shared
    # hands the server a routable address directly, so there is no floating
    # IP to attach.  See t/create-vm-no-floating-ip.t for that path.
}

# --- look_by_id_or_name error path ---

{
    note "look_by_id_or_name: dies when resource not found";

    # Mock an empty server list so lookup fails
    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers',
        application_json('{"servers": []}'),
    );

    like dies { $api->look_by_id_or_name('servers', 'nonexistent') },
      qr/Cannot find 'servers' for id\/name 'nonexistent'/,
      "look_by_id_or_name dies with resource type and search term";
}

# --- Missing arguments to constructor ---

{
    note "OpenStack::MetaAPI->new() without arguments";

    like dies { OpenStack::MetaAPI->new() },
      qr/Missing arguments to create Auth object/,
      "new() without arguments gives useful error";
}

done_testing;
