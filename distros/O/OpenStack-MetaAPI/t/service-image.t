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
        'id'           => 'b763530-fe64d-2116b5-c627a7-7f0cf71b',
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

done_testing;

sub json_for_image {

# https://developer.openstack.org/api-ref/compute/?expanded=show-server-details-detail
    return <<'JSON';
{
   "min_ram" : 0,
   "id" : "b763530-fe64d-2116b5-c627a7-7f0cf71b",
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

__END__
