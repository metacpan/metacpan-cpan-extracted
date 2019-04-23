#!/usr/bin/env perl

package Test::OpenStack::MetaAPI::Auth;

use strict;
use warnings;

use Test::More;    # for note & co
use Test::MockModule;
use JSON ();

use Test::OpenStack::MetaAPI qw{:all};

use Exporter 'import';
our @EXPORT_OK = qw(
  get_api_object
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# this can be shared by all our unit tests
sub get_api_object {
    my (%opts) = @_;

    local %ENV = %ENV;

    if (!$opts{use_env}) {

        # by default do not use ENV to perorm all requests
        %ENV = (
            OS_USERNAME     => 'MyUsername',
            OS_PASSWORD     => 'MyPassword',
            OS_AUTH_URL     => 'http://127.0.0.1:923',
            OS_PROJECT_NAME => 'myOpenStackProject',
        );

        mock_post_request(
            $ENV{OS_AUTH_URL} . '/auth/tokens',
            {   content => json_for_auth(),
                headers => [
                    ['Content-Type'    => 'application/json'],
                    ['X-Subject-Token' => 'custom-token'],
                ],
            });

    }

    my $api = OpenStack::MetaAPI->new(
        $ENV{OS_AUTH_URL},
        username => $ENV{'OS_USERNAME'},
        password => $ENV{'OS_PASSWORD'},
        version  => 3,
        scope    => {
            project => {
                name   => $ENV{'OS_PROJECT_NAME'},
                domain => {id => 'default'},
            }
          }

    );

    return $api;
}

sub json_for_auth {

    return <<'JSON';
{
    "token" : {
       "expires_at" : "2019-04-19T03:35:02.000000Z",
       "issued_at" : "2199-04-18T19:35:02.000000Z",
       "catalog" : [
          {
             "name" : "placement",
             "endpoints" : [
                {
                   "region" : "RegionOne",
                   "id" : "b3c2cadb0c5f52afdf783b18070ffa5c",
                   "interface" : "internal",
                   "url" : "http://127.0.0.1:8778",
                   "region_id" : "RegionOne"
                },
                {
                   "region_id" : "RegionOne",
                   "url" : "http://127.0.0.1:8778",
                   "region" : "RegionOne",
                   "id" : "edb404962d8e2d813d4f4b001f7f1d56",
                   "interface" : "admin"
                },
                {
                   "id" : "a1659e22251646c59fe14d56b607f518",
                   "interface" : "public",
                   "region" : "RegionOne",
                   "url" : "http://127.0.0.1:8778",
                   "region_id" : "RegionOne"
                }
             ],
             "type" : "placement",
             "id" : "4dae9a7fbc009470c134e18a7edfa989"
          },
          {
             "name" : "glance",
             "type" : "image",
             "endpoints" : [
                {
                   "interface" : "internal",
                   "id" : "a0fe7d24fb4e22d6f323a21708cec22e",
                   "region" : "RegionOne",
                   "url" : "http://127.0.0.1:9292",
                   "region_id" : "RegionOne"
                },
                {
                   "region_id" : "RegionOne",
                   "url" : "http://127.0.0.1:9292",
                   "id" : "576d20e78ecfd73c05ccad788e1d29cb",
                   "interface" : "admin",
                   "region" : "RegionOne"
                },
                {
                   "id" : "db9f9cb70155144582c82495b0e87adb",
                   "interface" : "public",
                   "region" : "RegionOne",
                   "region_id" : "RegionOne",
                   "url" : "http://127.0.0.1:9292"
                }
             ],
             "id" : "f621761733d56912f6e68fccfcebc786"
          },
          {
             "id" : "fffbc6ae929bc74b5527827d8ce482b1",
             "name" : "neutron",
             "type" : "network",
             "endpoints" : [
                {
                   "url" : "http://127.0.0.1:9696",
                   "region_id" : "RegionOne",
                   "id" : "4155b6aa9955295e3562aa6033c68179",
                   "interface" : "internal",
                   "region" : "RegionOne"
                },
                {
                   "region" : "RegionOne",
                   "id" : "f01cfc4381e536948711c42492c22d41",
                   "interface" : "admin",
                   "url" : "http://127.0.0.1:9696",
                   "region_id" : "RegionOne"
                },
                {
                   "id" : "375304083f3a03b02e87ce11cde2b8db",
                   "interface" : "public",
                   "region" : "RegionOne",
                   "region_id" : "RegionOne",
                   "url" : "http://127.0.0.1:9696"
                }
             ]
          },
          {
             "id" : "b0df02503332e9dafa7a72017b51523c",
             "endpoints" : [
                {
                   "interface" : "admin",
                   "id" : "3f8aab541f1524943b5de6bd1fd25159",
                   "region" : "RegionOne",
                   "region_id" : "RegionOne",
                   "url" : "http://127.0.0.1:8776/v2/76fb18aec577491bb676b482f5671352"
                },
                {
                   "interface" : "internal",
                   "id" : "edfda0d3cc43ca0e93189d4e1d6c45f7",
                   "region" : "RegionOne",
                   "url" : "http://127.0.0.1:8776/v2/76fb18aec577491bb676b482f5671352",
                   "region_id" : "RegionOne"
                },
                {
                   "id" : "0f23cbbd8552a8a0db043cf3d2dd0fa8",
                   "interface" : "public",
                   "region" : "RegionOne",
                   "url" : "http://127.0.0.1:8776/v2/76fb18aec577491bb676b482f5671352",
                   "region_id" : "RegionOne"
                }
             ],
             "type" : "volumev2",
             "name" : "cinderv2"
          },
          {
             "name" : "nova",
             "endpoints" : [
                {
                   "interface" : "internal",
                   "id" : "7b9cbbaa509200b75cb215ee40590c42",
                   "region" : "RegionOne",
                   "region_id" : "RegionOne",
                   "url" : "http://127.0.0.1:8774/v2.1"
                },
                {
                   "region" : "RegionOne",
                   "id" : "c34d2eabc042c02166b25ab13579c21a",
                   "interface" : "public",
                   "region_id" : "RegionOne",
                   "url" : "http://127.0.0.1:8774/v2.1"
                },
                {
                   "region" : "RegionOne",
                   "interface" : "admin",
                   "id" : "43ce670c6180b9a82743d518f7b3a989",
                   "region_id" : "RegionOne",
                   "url" : "http://127.0.0.1:8774/v2.1"
                }
             ],
             "type" : "compute",
             "id" : "34468fe5daa9d5e31a5efc5751956df0"
          },
          {
             "name" : "cinder",
             "type" : "volume",
             "endpoints" : [
                {
                   "region_id" : "RegionOne",
                   "url" : "http://127.0.0.1:8776/v1/76fb18aec577491bb676b482f5671352",
                   "id" : "f8dd6e324051f6a5ad840edf1c69d537",
                   "interface" : "internal",
                   "region" : "RegionOne"
                },
                {
                   "interface" : "admin",
                   "id" : "877132faee97b6a16a4233e503a4b426",
                   "region" : "RegionOne",
                   "region_id" : "RegionOne",
                   "url" : "http://127.0.0.1:8776/v1/76fb18aec577491bb676b482f5671352"
                },
                {
                   "url" : "http://127.0.0.1:8776/v1/76fb18aec577491bb676b482f5671352",
                   "region_id" : "RegionOne",
                   "id" : "a592856d9f221da14ac35e2ec7f9e9b1",
                   "interface" : "public",
                   "region" : "RegionOne"
                }
             ],
             "id" : "62c4df8be0c421478e26e6eab2e7a166"
          },
          {
             "type" : "volumev3",
             "endpoints" : [
                {
                   "interface" : "public",
                   "id" : "3acde32893c07809a5cd842262c326d2",
                   "region" : "RegionOne",
                   "region_id" : "RegionOne",
                   "url" : "http://127.0.0.1:8776/v3/76fb18aec577491bb676b482f5671352"
                },
                {
                   "id" : "eb1ba3da5cc3fb37dec1172719d88d0b",
                   "interface" : "internal",
                   "region" : "RegionOne",
                   "url" : "http://127.0.0.1:8776/v3/76fb18aec577491bb676b482f5671352",
                   "region_id" : "RegionOne"
                },
                {
                   "region" : "RegionOne",
                   "id" : "d8cf1b05ec5857a81d3edb49ab74e6f4",
                   "interface" : "admin",
                   "region_id" : "RegionOne",
                   "url" : "http://127.0.0.1:8776/v3/76fb18aec577491bb676b482f5671352"
                }
             ],
             "name" : "cinderv3",
             "id" : "f2b992d728e228fbace64f88adc1fc34"
          },
          {
             "endpoints" : [
                {
                   "region" : "RegionOne",
                   "interface" : "admin",
                   "id" : "5b3aef25829785d99ad4d8ceedae4ba6",
                   "url" : "https://127.0.0.1:35358/",
                   "region_id" : "RegionOne"
                },
                {
                   "id" : "94c7a830fa0cf5ed8e91074ae33b6d04",
                   "interface" : "internal",
                   "region" : "RegionOne",
                   "url" : "https://127.0.0.1:5001/",
                   "region_id" : "RegionOne"
                },
                {
                   "url" : "https://127.0.0.1:5001/",
                   "region_id" : "RegionOne",
                   "region" : "RegionOne",
                   "interface" : "public",
                   "id" : "b0df02503332e9dafa7a72017b51523c"
                }
             ],
             "type" : "identity",
             "name" : "keystone",
             "id" : "d8a343fed838f929e487d6fb917fe0b7"
          }
       ],
       "user" : {
          "password_expires_at" : null,
          "name" : "Someone@here.tld",
          "domain" : {
             "name" : "Default",
             "id" : "default"
          },
          "id" : "8286"
       },
       "audit_ids" : [
          "kenFvl8CTwy44TIEq_1y3A"
       ],
       "project" : {
          "name" : "TestSuite Project",
          "id" : "0c5d4940d91b2fead7f1ec9a59bc4ec",
          "domain" : {
             "id" : "default",
             "name" : "Default"
          }
       },
       "methods" : [
          "password"
       ],
       "roles" : [
          {
             "name" : "_member_",
             "id" : "97f1a3b78fad4fcf3ca7338a9529a03"
          }
       ],
       "is_domain" : false
    }
 }
JSON

}

__END__
https://onlinerandomtools.com/generate-random-hexadecimal-numbers


1;
