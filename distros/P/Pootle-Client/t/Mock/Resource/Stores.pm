# This file is part of Pootle-Client.

package t::Mock::Resource::Stores;

use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use feature 'signatures'; no warnings "experimental::signatures";
use Carp::Always;
use Try::Tiny;
use Scalar::Util qw(blessed);


use base('t::Mock::Resource');

use Pootle::Resource::Store;

my $objects;
my $lookup;
my $responseDump;

sub one($papi, $endpoint) {
  ($objects, $lookup) = __PACKAGE__->init($responseDump, 'Pootle::Resource::Store') unless ($objects && $lookup);
  return $lookup->{$endpoint};
}

sub all($papi) {
  ($objects, $lookup) = __PACKAGE__->init($responseDump, 'Pootle::Resource::Store') unless ($objects && $lookup);
  return $objects if $objects;
}

$responseDump = [
  {
    'file' => '/media/17.05/fi/fi-FI-marc-MARC21.po',
    'name' => 'fi-FI-marc-MARC21.po',
    'pending' => undef,
    'pootle_path' => '/fi/17.05/fi-FI-marc-MARC21.po',
    'resource_uri' => '/api/v1/stores/7578/',
    'state' => 2,
    'sync_time' => '2017-10-15T10:37:00',
    'tm' => undef,
    'translation_project' => '/api/v1/translation-projects/1185/',
    'units' => [
      '/api/v1/units/20041894/',
      '/api/v1/units/20041895/',
      '/api/v1/units/20041896/',
      '/api/v1/units/20041897/',
    ]
  },
  {
    'file' => '/media/17.05/en_GB/en-GB-marc-MARC21.po',
    'name' => 'en-GB-marc-MARC21.po',
    'pending' => undef,
    'pootle_path' => '/en_GB/17.05/en-GB-marc-MARC21.po',
    'resource_uri' => '/api/v1/stores/7537/',
    'state' => 2,
    'sync_time' => '2017-10-15T10:28:13',
    'tm' => undef,
    'translation_project' => '/api/v1/translation-projects/1179/',
    'units' => [
      '/api/v1/units/19925512/',
      '/api/v1/units/19925513/',
      '/api/v1/units/19925514/',
      '/api/v1/units/19925515/',
    ],
  },
  {
    'file' => '/media/17.05/en_GB/en-GB-marc-NORMARC.po',
    'name' => 'en-GB-marc-NORMARC.po',
    'pending' => undef,
    'pootle_path' => '/en_GB/17.05/en-GB-marc-NORMARC.po',
    'resource_uri' => '/api/v1/stores/7539/',
    'state' => 2,
    'sync_time' => '2017-10-15T10:28:13',
    'tm' => undef,
    'translation_project' => '/api/v1/translation-projects/1179/',
    'units' => [
      '/api/v1/units/19927569/',
      '/api/v1/units/19927570/',
      '/api/v1/units/19927571/',
      '/api/v1/units/19927572/',
    ],
  },
  {
    'file' => '/media/17.05/en_GB/en-GB-marc-UNIMARC.po',
    'name' => 'en-GB-marc-UNIMARC.po',
    'pending' => undef,
    'pootle_path' => '/en_GB/17.05/en-GB-marc-UNIMARC.po',
    'resource_uri' => '/api/v1/stores/7538/',
    'state' => 2,
    'sync_time' => '2017-10-15T10:28:14',
    'tm' => undef,
    'translation_project' => '/api/v1/translation-projects/1179/',
    'units' => [
      '/api/v1/units/19928013/',
      '/api/v1/units/19928014/',
      '/api/v1/units/19928015/',
      '/api/v1/units/19928016/',
    ],
  },
  {
    'file' => '/media/17.05/en_GB/en-GB-opac-bootstrap.po',
    'name' => 'en-GB-opac-bootstrap.po',
    'pending' => undef,
    'pootle_path' => '/en_GB/17.05/en-GB-opac-bootstrap.po',
    'resource_uri' => '/api/v1/stores/7534/',
    'state' => 2,
    'sync_time' => '2017-10-15T10:28:34',
    'tm' => undef,
    'translation_project' => '/api/v1/translation-projects/1179/',
    'units' => [
      '/api/v1/units/19929806/',
      '/api/v1/units/19929809/',
      '/api/v1/units/19929810/',
      '/api/v1/units/19929811/',
    ],
  },
  {
    'file' => '/media/17.05/en_GB/en-GB-pref.po',
    'name' => 'en-GB-pref.po',
    'pending' => undef,
    'pootle_path' => '/en_GB/17.05/en-GB-pref.po',
    'resource_uri' => '/api/v1/stores/7540/',
    'state' => 2,
    'sync_time' => '2017-10-15T10:28:36',
    'tm' => undef,
    'translation_project' => '/api/v1/translation-projects/1179/',
    'units' => [
      '/api/v1/units/19931592/',
      '/api/v1/units/19931593/',
      '/api/v1/units/19931594/',
      '/api/v1/units/19931595/',
    ],
  },
  {
    'file' => '/media/17.05/en_GB/en-GB-staff-help.po',
    'name' => 'en-GB-staff-help.po',
    'pending' => undef,
    'pootle_path' => '/en_GB/17.05/en-GB-staff-help.po',
    'resource_uri' => '/api/v1/stores/7536/',
    'state' => 2,
    'sync_time' => '2017-10-15T10:28:38',
    'tm' => undef,
    'translation_project' => '/api/v1/translation-projects/1179/',
    'units' => [
      '/api/v1/units/19933549/',
      '/api/v1/units/19933550/',
      '/api/v1/units/19933551/',
      '/api/v1/units/19933552/',
    ],
  },
  {
    'file' => '/media/17.05/en_GB/en-GB-staff-prog.po',
    'name' => 'en-GB-staff-prog.po',
    'pending' => undef,
    'pootle_path' => '/en_GB/17.05/en-GB-staff-prog.po',
    'resource_uri' => '/api/v1/stores/7535/',
    'state' => 2,
    'sync_time' => '2017-10-15T10:29:01',
    'tm' => undef,
    'translation_project' => '/api/v1/translation-projects/1179/',
    'units' => [
      '/api/v1/units/19936592/',
      '/api/v1/units/19936593/',
      '/api/v1/units/19936594/',
      '/api/v1/units/19936595/',
    ],
  },
];

1;
