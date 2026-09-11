#!/usr/bin/env perl

use strict;
use warnings;

use OpenStack::MetaAPI ();

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::OpenStack::MetaAPI      qw{:all};
use Test::OpenStack::MetaAPI::Auth qw{:all};

use JSON;

mock_lwp_useragent();

my $NOVA   = 'http://127.0.0.1:8774/v2.1';
my $CINDER = 'http://127.0.0.1:8776/v3/76fb18aec577491bb676b482f5671352';

my $api = get_api_object(use_env => 0);
ok $api, "got one api object" or die;

{
    note "limits: the allowance and the usage in one answer";

    mock_get_request(
        "$NOVA/limits",
        application_json(
            encode_json(
                {   limits => {
                        absolute => {
                            maxTotalRAMSize     => 51200,
                            totalRAMUsed        => 8192,
                            maxTotalCores       => 40,
                            totalCoresUsed      => 6,
                            maxTotalInstances   => 20,
                            totalInstancesUsed  => 3,
                        }
                    }
                }
            )
        ),
    );

    my $limits = $api->limits;
    is $limits->{absolute}{maxTotalRAMSize}, 51200, "the allowance";
    is $limits->{absolute}{totalRAMUsed},    8192,  "and the usage, without adding up a server list";
}

{
    note "server_action: one POST, one single-key body";

    mock_post_request("$NOVA/servers/abc123/action", application_json('{}'));

    ok $api->server_action('abc123', {reboot => {type => 'SOFT'}}), "an action goes through";
    is last_http_request(), "POST $NOVA/servers/abc123/action", "to the action endpoint";

    like dies { $api->server_action('', {reboot => {}}) }, qr/server id is required/,
      "and it wants a server";
    like dies { $api->server_action('abc123', 'reboot') }, qr/must be a hash reference/,
      "and an action it can encode";
}

{
    note "create_image: a snapshot is an action";

    mock_post_request("$NOVA/servers/abc123/action", application_json('{}'));

    ok $api->create_image('abc123', name => 'before-upgrade'), "snapshotting goes through";
    like dies { $api->create_image('abc123') }, qr/'name' is required/,
      "an image with no name is not a snapshot anyone can find again";
}

{
    note "flavors_detail: the one that knows how many CPUs";

    mock_get_request(
        "$NOVA/flavors/detail",
        application_json(
            encode_json(
                {   flavors => [
                        {id => '1', name => 'm1.small',  vcpus => 1, ram => 2048, disk => 20},
                        {id => '2', name => 'm1.medium', vcpus => 2, ram => 4096, disk => 40},
                    ]
                }
            )
        ),
    );

    my @all = $api->flavors_detail;
    is scalar @all, 2, "both flavors";
    is $all[1]{vcpus}, 2, "with the numbers the summary list leaves out";

    my @one = $api->flavors_detail(name => 'm1.medium');
    is scalar @one,   1,           "filtered by name";
    is $one[0]{id},   '2',         "the right one";
}

{
    note "console_output: what the guest said before it gave up";

    mock_post_request(
        "$NOVA/servers/abc123/action",
        application_json( encode_json( {output => "cloud-init done\n"} ) ),
    );

    is $api->console_output('abc123', 50), "cloud-init done\n", "the text, not the envelope";
}

{
    note "volume attachments are Nova's, not Cinder's";

    mock_get_request(
        "$NOVA/servers/abc123/os-volume_attachments",
        application_json( encode_json( {volumeAttachments => [{id => 'v1', device => '/dev/vdb'}]} ) ),
    );

    my @attached = $api->server_volumes('abc123');
    is scalar @attached,      1,           "one attachment";
    is $attached[0]{device}, '/dev/vdb',   "and where it landed";

    mock_post_request(
        "$NOVA/servers/abc123/os-volume_attachments",
        application_json( encode_json( {volumeAttachment => {id => 'v1', device => '/dev/vdb'}} ) ),
    );
    is $api->attach_volume('abc123', 'v1')->{device}, '/dev/vdb', "attaching returns the attachment";

    like dies { $api->attach_volume('abc123', '') }, qr/volume id is required/, "and wants a volume";
    like dies { $api->detach_volume('abc123', '') }, qr/volume id is required/, "so does detaching";
}

{
    note "the volume service resolves to whichever cinder the catalogue offers";

    mock_get_request(
        "$CINDER/volumes",
        application_json( encode_json( {volumes => [{id => 'v1', name => 'data'}]} ) ),
    );

    # The fixture catalogue lists volumev3, volumev2 and volume; newest wins,
    # which is what puts this request at the /v3/ endpoint.
    my $vol = $api->volumes;
    is $vol->{name}, 'data', "listed through the v3 endpoint";
    like last_http_request(), qr{\Q$CINDER/volumes\E}, "which is the one that got asked";

    mock_post_request(
        "$CINDER/volumes",
        application_json( encode_json( {volume => {id => 'v2', size => 10}} ) ),
    );
    is $api->create_volume(size => 10)->{id}, 'v2', "creating one";
    like dies { $api->create_volume() }, qr/'size' is required/, "a volume needs a size";

    mock_delete_request("$CINDER/volumes/v2", application_json('{}'));
    ok $api->delete_volume('v2'), "deleting one";
    like dies { $api->delete_volume('') }, qr/volume id is required/, "and it wants to know which";
}

done_testing;
