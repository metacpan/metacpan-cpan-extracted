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

$Test::OpenStack::MetaAPI::UA_DISPLAY_OUTPUT = 1;

my $api = get_api_object(use_env => 0);

ok $api, "got one api object" or die;

{
    note "Testing images service";

    mock_get_request(
        'http://127.0.0.1:9292/v2/images/170fafa5-1329-44a3-9c27-9bb77b77206d',
        application_json(json_for_image()),
    );

    # sub image_from_name {

    my $IMAGE_UID  = '170fafa5-1329-44a3-9c27-9bb77b77206d';
    my $IMAGE_NAME = 'myimage';

    like $api->image_from_uid($IMAGE_UID),

      { 'base'             => 'False',
        'checksum'         => 'fdbb43d0cd6019f82b4cf73b882608d1',
        'container_format' => 'bare',
        'created_at'       => '2019-04-10T20:23:09Z',
        'disk_format'      => 'raw',
        'file'         => '/v2/images/6056cbf415fd5f8c223c8a69341e44ee/file',
        'id'           => 'b7635300-fe6d-2116-c627-7f0cf71b0000',
        'min_disk'     => 0,
        'min_ram'      => 0,
        'name'         => 'MyImage',
        'os_arch'      => 'x86_64',
        'os_distro'    => 'centos',
        'os_version'   => '7',
        'owner'        => '84862e1b8aa5d5a6a6d9106e377fff96',
        'protected'    => D(),
        'schema'       => '/v2/schemas/image',
        'self'         => '/v2/images/6056cbf415fd5f8c223c8a69341e44ee',
        'size'         => '12884901888',
        'status'       => 'active',
        'tags'         => [],
        'updated_at'   => '2019-04-10T20:24:49Z',
        'virtual_size' => undef,
        'visibility'   => 'shared'}

      , "image_from_uid";
    #
    mock_get_request(
        'http://127.0.0.1:9292/v2/images?name=in:%22myimage%22',
        application_json(json_for_image_name()),
    );

    is $api->image_from_name($IMAGE_NAME),
      { 'base'             => 'False',
        'checksum'         => '11c3b2d38e00b0cce4ab0dec720d42ad',
        'container_format' => 'bare',
        'created_at'       => '2019-04-10T20:23:09Z',
        'disk_format'      => 'raw',
        'file'         => '/v2/images/11c3b2d38e00b0cce4ab0dec720d42ad/file',
        'id'           => '2ad246436b89fa939e3ac435f268d8e9',
        'min_disk'     => 0,
        'min_ram'      => 0,
        'name'         => 'myimage-from-name',
        'os_arch'      => 'x86_64',
        'os_distro'    => 'centos',
        'os_version'   => '7',
        'owner'        => '79ee01d32d3c2dfec7d693743aeffa7b',
        'protected'    => bless(do { \(my $o = 0) }, 'JSON::PP::Boolean'),
        'schema'       => '/v2/schemas/image',
        'self'         => '/v2/images/11c3b2d38e00b0cce4ab0dec720d42ad',
        'size'         => '12884901888',
        'status'       => 'active',
        'tags'         => [],
        'updated_at'   => '2019-04-10T20:24:49Z',
        'virtual_size' => undef,
        'visibility'   => 'shared'
      },
      "image_from_name";

    is last_http_request(),
      'GET http://127.0.0.1:9292/v2/images?name=in:%22myimage%22',
      'last_http_request';

}

{
    note "Testing image_from_uid rejects malformed UUIDs";

    like dies { $api->image_from_uid('not-a-uuid') },
        qr/Invalid UUID format/,
        "image_from_uid rejects non-UUID string";

    like dies { $api->image_from_uid('aaa-bbb-ccc') },
        qr/Invalid UUID format/,
        "image_from_uid rejects too-short hex-dash string";

    like dies { $api->image_from_uid('170fafa513294a3c9c279bb77b77206d') },
        qr/Invalid UUID format/,
        "image_from_uid rejects UUID without dashes";

    like dies { $api->image_from_uid('170fafa5-1329-44a3-9c27') },
        qr/Invalid UUID format/,
        "image_from_uid rejects truncated UUID";
}

{
    note "Testing images() is not exposed at MetaAPI level";

    ok !$api->can('images'),
      "images() is not available via MetaAPI (use image_from_uid or image_from_name)";
}

{
    note "Testing image_from_uid requires uid parameter";

    like dies { $api->image_from_uid(undef) },
      qr/image_from_uid: uid is required/,
      "image_from_uid dies when uid is undef";
}

{
    note "Testing image_from_name requires name parameter";

    like dies { $api->image_from_name(undef) },
      qr/image_from_name: name is required/,
      "image_from_name dies when name is undef";
}

{
    note "Testing image_from_name with duplicate image names";

    mock_get_request(
        'http://127.0.0.1:9292/v2/images?name=in:%22duplicate-image%22',
        application_json(json_for_duplicate_images()),
    );

    like dies { $api->image_from_name('duplicate-image') },
      qr/multiple images found for name 'duplicate-image'/,
      "image_from_name dies on duplicate names";

    like dies { $api->image_from_name('duplicate-image') },
      qr/Use image_from_uid to select a specific image/,
      "error message suggests using image_from_uid";
}

{
    note "Testing image_from_name with no results";

    mock_get_request(
        'http://127.0.0.1:9292/v2/images?name=in:%22nonexistent%22',
        application_json(json_for_no_images()),
    );

    is $api->image_from_name('nonexistent'), undef,
      "image_from_name returns undef when no images found";
}

done_testing;

sub json_for_image {

# https://developer.openstack.org/api-ref/compute/?expanded=show-server-details-detail
    return <<'JSON';
{
   "min_ram" : 0,
   "id" : "b7635300-fe6d-2116-c627-7f0cf71b0000",
   "os_version" : "7",
   "created_at" : "2019-04-10T20:23:09Z",
   "os_arch" : "x86_64",
   "min_disk" : 0,
   "owner" : "84862e1b8aa5d5a6a6d9106e377fff96",
   "name" : "MyImage",
   "container_format" : "bare",
   "visibility" : "shared",
   "updated_at" : "2019-04-10T20:24:49Z",
   "size" : 12884901888,
   "status" : "active",
   "tags" : [],
   "protected" : false,
   "base" : "False",
   "self" : "/v2/images/6056cbf415fd5f8c223c8a69341e44ee",
   "file" : "/v2/images/6056cbf415fd5f8c223c8a69341e44ee/file",
   "schema" : "/v2/schemas/image",
   "disk_format" : "raw",
   "os_distro" : "centos",
   "checksum" : "fdbb43d0cd6019f82b4cf73b882608d1",
   "virtual_size" : null
}
JSON
}

sub json_for_image_name {
    return <<'JSON';
{
   "first" : "/v2/images?name=in%3A%22myimage%22",
   "schema" : "/v2/schemas/images",
   "images" : [
      {
         "file" : "/v2/images/11c3b2d38e00b0cce4ab0dec720d42ad/file",
         "virtual_size" : null,
         "min_ram" : 0,
         "min_disk" : 0,
         "name" : "myimage-from-name",
         "updated_at" : "2019-04-10T20:24:49Z",
         "protected" : false,
         "checksum" : "11c3b2d38e00b0cce4ab0dec720d42ad",
         "self" : "/v2/images/11c3b2d38e00b0cce4ab0dec720d42ad",
         "os_distro" : "centos",
         "os_arch" : "x86_64",
         "size" : 12884901888,
         "container_format" : "bare",
         "status" : "active",
         "visibility" : "shared",
         "disk_format" : "raw",
         "schema" : "/v2/schemas/image",
         "id" : "2ad246436b89fa939e3ac435f268d8e9",
         "tags" : [],
         "os_version" : "7",
         "created_at" : "2019-04-10T20:23:09Z",
         "base" : "False",
         "owner" : "79ee01d32d3c2dfec7d693743aeffa7b"
      }
   ]
}
JSON
}

sub json_for_duplicate_images {
    return <<'JSON';
{
   "first" : "/v2/images?name=in%3A%22duplicate-image%22",
   "schema" : "/v2/schemas/images",
   "images" : [
      {
         "id" : "aaaa1111-2222-3333-4444-555566667777",
         "name" : "duplicate-image",
         "status" : "active",
         "visibility" : "shared"
      },
      {
         "id" : "bbbb1111-2222-3333-4444-555566667777",
         "name" : "duplicate-image",
         "status" : "active",
         "visibility" : "shared"
      }
   ]
}
JSON
}

sub json_for_no_images {
    return <<'JSON';
{
   "first" : "/v2/images?name=in%3A%22nonexistent%22",
   "schema" : "/v2/schemas/images",
   "images" : []
}
JSON
}

__END__
