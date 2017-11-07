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

use t::Mock::Client;


my $module = new Test::MockModule('Pootle::Client');
$module->mock('languages', \&t::Mock::Client::languages);
$module->mock('projects', \&t::Mock::Client::projects);


ok(my $papi = t::Mock::Client::new(),
   "Given a Pootle::Client connection");
ok(my $langs = $papi->languages(),
   "Given all languages in Pootle to filter");
ok(my $projs = $papi->projects(),
   "Given all projects in Pootle to filter");


subtest "Picking a group of results", \&pickGroup;
sub pickGroup {
  my $filters;
  eval {

  ok(my $filters = Pootle::Filters->new({filters => {
      fullname => qr/^English/,
      code => qr/^en/,
    }
  }),
     "Given filters to pick English dialects");

  ok(my $languages = $filters->filter($langs),
     "When all languages are filtered with given filters");

  is(@$languages, 5,
     "Then we found 5 languages matching the given filters");

  is($languages->[1]->code, 'en_GB',
     "And language code matches en_GB");
  is($languages->[1]->fullname, 'English (United Kingdom)',
     "And full name matches");
  is($languages->[3]->code, 'en_ZA',
     "And language code matches en_ZA");
  is($languages->[3]->fullname, 'English (South Africa)',
     "And full name matches");

  };
  if ($@) {
    ok(0, $@);
  }
};

subtest "Picking a single result", \&pickSingle;
sub pickSingle {
  my ($filters, $languages);
  eval {

  ok($filters = Pootle::Filters->new({filters => {
      fullname => qr/^Finnish/,
      code => qr/^fi/,
    }
  }),
     "Given filters to pick the Finnish language");

  ok($languages = $filters->filter($langs),
     "When all languages are filtered with given filters");

  is(@$languages, 1,
     "Then we found 1 language matching the given filters");

  is($languages->[0]->code, 'fi',
     "And language code matches");
  is($languages->[0]->fullname, 'Finnish',
     "And full name matches");

  };
  if ($@) {
    ok(0, $@);
  }
};

subtest "Intersect a shared attribute from two groups of resources", \&intersect;
sub intersect {
  my ($langFilters, $projFilters, $translationProjects, $filteredLanguages, $filteredProjects);
  eval {

  ok($langFilters = Pootle::Filters->new({filters => {
      fullname => qr/^Finnish/,
      code => qr/^fi/,
    }
  }),
     "Given filters to pick the Finnish language");

  ok($projFilters = Pootle::Filters->new({filters => {
      code => qr/^(marc21)|(17\.05)/,
    }
  }),
     "Given filters to pick projects, 17.05, marc21");

  ok($filteredLanguages = $langFilters->filter($langs),
     "Given languages to be intersected");

  ok($filteredProjects = $projFilters->filter($projs),
     "Given projects to be intersected");

  ok($translationProjects = Pootle::Filters->new()->intersect($filteredLanguages, $filteredProjects, 'translation_projects', 'translation_projects'),
     "When given languages and projects are intersected looking for common translation projects");

  is(@$translationProjects, 2,
     "Then we found 2 shared translation projects");

  is(ref($translationProjects->[0]), 'Pootle::Filters::Intersection',
     "And results are Intersection-objects");
  is_deeply($translationProjects->[0]->obj1, $filteredLanguages->[0],
     "And obj1 is a Pootle::Resource::Language from the pre-filtered languages set");
  is_deeply($translationProjects->[1]->obj2, $filteredProjects->[0],
     "And obj2 is a Pootle::Resource::Project from the pre-filtered projects set");

  };
  if ($@) {
    ok(0, $@);
  }
};

done_testing();
