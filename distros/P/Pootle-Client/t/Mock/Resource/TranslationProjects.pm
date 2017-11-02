# This file is part of Pootle-Client.

package t::Mock::Resource::TranslationProjects;

use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use feature 'signatures'; no warnings "experimental::signatures";
use Carp::Always;
use Try::Tiny;
use Scalar::Util qw(blessed);


use base('t::Mock::Resource');

use Pootle::Resource::TranslationProject;

my $objects;
my $lookup;
my $responseDump;

sub one($papi, $endpoint) {
  ($objects, $lookup) = __PACKAGE__->init($responseDump, 'Pootle::Resource::TranslationProject') unless ($objects && $lookup);
  return $lookup->{$endpoint};
}

sub all($papi) {
  ($objects, $lookup) = __PACKAGE__->init($responseDump, 'Pootle::Resource::TranslationProject') unless ($objects && $lookup);
  return $objects if $objects;
}

$responseDump = [
  {
    'description' => '',
    'language' => '/api/v1/languages/111/',
    'pootle_path' => '/fi/34/',
    'project' => '/api/v1/projects/5/',
    'real_path' => '34/fi',
    'resource_uri' => '/api/v1/translation-projects/124/',
    'stores' => [
      '/api/v1/stores/273/',
      '/api/v1/stores/274/',
      '/api/v1/stores/272/'
    ]
  },
  {
    'description' => '',
    'language' => '/api/v1/languages/111/',
    'pootle_path' => '/fi/36/',
    'project' => '/api/v1/projects/6/',
    'real_path' => '36/fi',
    'resource_uri' => '/api/v1/translation-projects/142/',
    'stores' => [
      '/api/v1/stores/468/',
      '/api/v1/stores/469/',
      '/api/v1/stores/467/'
    ]
  },
  {
    'description' => '',
    'language' => '/api/v1/languages/111/',
    'pootle_path' => '/fi/17.05/',
    'project' => '/api/v1/projects/26/',
    'real_path' => '17.05/fi',
    'resource_uri' => '/api/v1/translation-projects/1185/',
    'stores' => [
      '/api/v1/stores/7578/',
      '/api/v1/stores/7576/',
      '/api/v1/stores/7582/',
      '/api/v1/stores/7579/',
      '/api/v1/stores/7580/',
      '/api/v1/stores/7577/',
      '/api/v1/stores/7581/'
    ]
  },
  {
    'description' => '',
    'language' => '/api/v1/languages/88/',
    'pootle_path' => '/am/16.05/',
    'project' => '/api/v1/projects/23/',
    'real_path' => '16.05/am',
    'resource_uri' => '/api/v1/translation-projects/989/',
    'stores' => [
      '/api/v1/stores/5824/',
      '/api/v1/stores/5827/',
      '/api/v1/stores/5825/',
      '/api/v1/stores/5821/',
      '/api/v1/stores/5826/',
      '/api/v1/stores/5823/',
      '/api/v1/stores/5822/'
    ]
  },
  {
    'description' => '',
    'language' => '/api/v1/languages/130/',
    'pootle_path' => '/en_NZ/17.05/',
    'project' => '/api/v1/projects/26/',
    'real_path' => '17.05/en_NZ',
    'resource_uri' => '/api/v1/translation-projects/1180/',
    'stores' => [
      '/api/v1/stores/7545/',
      '/api/v1/stores/7543/',
      '/api/v1/stores/7546/',
      '/api/v1/stores/7547/',
      '/api/v1/stores/7541/',
      '/api/v1/stores/7542/',
      '/api/v1/stores/7544/'
    ]
  },
  {
    'description' => '',
    'language' => '/api/v1/languages/69/',
    'pootle_path' => '/en_GB/17.05/',
    'project' => '/api/v1/projects/26/',
    'real_path' => '17.05/en_GB',
    'resource_uri' => '/api/v1/translation-projects/1179/',
    'stores' => [
      '/api/v1/stores/7537/',
      '/api/v1/stores/7539/',
      '/api/v1/stores/7538/',
      '/api/v1/stores/7534/',
      '/api/v1/stores/7540/',
      '/api/v1/stores/7536/',
      '/api/v1/stores/7535/'
    ]
  },
];

1;
