# Copyright (C) 2017 Koha-Suomi
#
# This file is part of Pootle-Client.

use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use FindBin;
use lib "$FindBin::Bin/../";
use feature 'signatures'; no warnings "experimental::signatures";
use Carp::Always;
use Try::Tiny;
use Scalar::Util qw(blessed);
use Data::Dumper;

use Test::More;
use Test::MockModule;

use Pootle::Client;
use Pootle::Filters;
use Pootle::Resource::TranslationProject;

use t::Mock::Client;


my $module = new Test::MockModule('Pootle::Client');
$module->mock('languages', \&t::Mock::Client::languages);
$module->mock('projects', \&t::Mock::Client::projects);
$module->mock('translationProject', \&t::Mock::Client::translationProject);
$module->mock('store',     \&t::Mock::Client::store);


ok(my $papi = t::Mock::Client::new(),
   "Given a Pootle::Client connection");
ok(my $langs = $papi->languages(),
   "Given all languages in Pootle to filter");
ok(my $projs = $papi->projects(),
   "Given all projects in Pootle to filter");

ok(my $langFilters = Pootle::Filters->new({filters => {
    fullname => qr/^English/,
    code => qr/^en/,
  }
}),
   "Given filters to pick English dialects");

ok(my $projFilters = Pootle::Filters->new({filters => {
    fullname => qr/^Koha 17/,
  }
}),
   "Given filters to pick Koha 17.* projects");

subtest "Scenario: Find translation projects", \&findTranslationProjects;
sub findTranslationProjects {
  my ($transProjs);
  eval {

  ok($transProjs = $papi->searchTranslationProjects($langFilters, $projFilters),
     "When translation projects are searched");

  is(@$transProjs, 2,
     "Then we found 2 translation projects matching filter criteria");

  is_deeply($transProjs->[0], Pootle::Resource::TranslationProject->new({
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
  }),
    "And the TranslationProject is as expected");

  is_deeply($transProjs->[1], Pootle::Resource::TranslationProject->new({
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
  }),
    "And the TranslationProject is as expected");

  };
  if ($@) {
    ok(0, $@);
  }
};

subtest "Scenario: Find translation files by languages and projects", \&findFiles;
sub findFiles {
  my ($stores);
  eval {

  ok(my $langFilters = Pootle::Filters->new({filters => {
      fullname => qr/^English/,
      code => qr/^en_GB/,
    }
  }),
    "Given filters to pick British language");

  ok($stores = $papi->searchStores($langFilters, $projFilters),
    "When stores are searched");

  is(@$stores, 7,
    "Then we found 7 stores matching filter criteria");

  is_deeply($stores->[0], Pootle::Resource::Store->new({
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
  }),
    "And the Store is as expected");

  is_deeply($stores->[6], Pootle::Resource::Store->new({
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
  }),
    "And the Store is as expected");

  };
  if ($@) {
    ok(0, $@);
  }
};

t::Mock::Client::cleanup($papi);

done_testing();
