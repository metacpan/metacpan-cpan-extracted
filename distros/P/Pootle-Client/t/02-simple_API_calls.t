# Copyright (C) 2017 Koha-Suomi
#
# This file is part of Pootle-Client.

use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use feature 'signatures'; no warnings "experimental::signatures";
use Carp::Always;
use Try::Tiny;
use Scalar::Util qw(blessed);
use Data::Dumper;

use Test::More;
use Test::MockModule;

use Pootle::Resource::Language;
use Pootle::Resource::Project;
use Pootle::Resource::TranslationProject;
use Pootle::Resource::Store;
use Pootle::Resource::Unit;

use t::Mock::Client;


my $module = new Test::MockModule('Pootle::Client');
$module->mock('languages', \&t::Mock::Client::languages);
$module->mock('language',  \&t::Mock::Client::language);
$module->mock('projects',  \&t::Mock::Client::projects);
$module->mock('project',   \&t::Mock::Client::project);
$module->mock('store',     \&t::Mock::Client::store);
$module->mock('translationProjects',   \&t::Mock::Client::translationProjects);
$module->mock('translationProject',    \&t::Mock::Client::translationProject);
$module->mock('unit',      \&t::Mock::Client::unit);


ok(my $papi = t::Mock::Client::new(),
   "Given a Pootle::Client connection");


subtest "Languages", \&languages;
sub languages {
  my $expectedObject = Pootle::Resource::Language->new({
    'code' => 'fi',
    'description' => '',
    'fullname' => 'Finnish',
    'nplurals' => 2,
    'pluralequation' => '(n != 1)',
    'resource_uri' => '/api/v1/languages/111/',
    'specialchars' => '',
    'translation_projects' => [
      '/api/v1/translation-projects/124/',
      '/api/v1/translation-projects/142/',
      '/api/v1/translation-projects/220/',
      '/api/v1/translation-projects/236/',
      '/api/v1/translation-projects/277/',
      '/api/v1/translation-projects/414/',
      '/api/v1/translation-projects/528/',
      '/api/v1/translation-projects/592/',
      '/api/v1/translation-projects/621/',
      '/api/v1/translation-projects/709/',
      '/api/v1/translation-projects/843/',
      '/api/v1/translation-projects/911/',
      '/api/v1/translation-projects/1008/',
      '/api/v1/translation-projects/1103/',
      '/api/v1/translation-projects/1185/'
    ]
  });
  _runSimpleTests('languages', 141, 'language', '/api/v1/languages/111/', $expectedObject);
};

subtest "Projects", \&projects;
sub projects {
  my $expectedObject = Pootle::Resource::Project->new({
    'checkstyle' => 'standard',
    'code' => '16.05',
    'description' => '',
    'fullname' => 'Koha 16.05',
    'ignoredfiles' => '',
    'localfiletype' => 'po',
    'resource_uri' => '/api/v1/projects/23/',
    'source_language' => '/api/v1/languages/2/',
    'translation_projects' => [
      '/api/v1/translation-projects/989/',
      '/api/v1/translation-projects/990/',
      '/api/v1/translation-projects/991/',
      '/api/v1/translation-projects/992/',
      '/api/v1/translation-projects/993/',
      '/api/v1/translation-projects/994/',
      '/api/v1/translation-projects/995/',
      '/api/v1/translation-projects/996/',
      '/api/v1/translation-projects/997/',
      '/api/v1/translation-projects/998/',
      '/api/v1/translation-projects/999/',
      '/api/v1/translation-projects/1000/',
      '/api/v1/translation-projects/1001/',
      '/api/v1/translation-projects/1002/',
      '/api/v1/translation-projects/1003/',
      '/api/v1/translation-projects/1004/',
      '/api/v1/translation-projects/1005/',
      '/api/v1/translation-projects/1006/',
      '/api/v1/translation-projects/1007/',
      '/api/v1/translation-projects/1008/',
      '/api/v1/translation-projects/1009/',
      '/api/v1/translation-projects/1010/',
      '/api/v1/translation-projects/1011/',
      '/api/v1/translation-projects/1012/',
      '/api/v1/translation-projects/1013/',
      '/api/v1/translation-projects/1014/',
      '/api/v1/translation-projects/1015/',
      '/api/v1/translation-projects/1016/',
      '/api/v1/translation-projects/1017/',
      '/api/v1/translation-projects/1018/',
      '/api/v1/translation-projects/1019/',
      '/api/v1/translation-projects/1020/',
      '/api/v1/translation-projects/1021/',
      '/api/v1/translation-projects/1022/',
      '/api/v1/translation-projects/1023/',
      '/api/v1/translation-projects/1024/',
      '/api/v1/translation-projects/1025/',
      '/api/v1/translation-projects/1026/',
      '/api/v1/translation-projects/1027/',
      '/api/v1/translation-projects/1028/',
      '/api/v1/translation-projects/1029/',
      '/api/v1/translation-projects/1030/',
      '/api/v1/translation-projects/1031/',
      '/api/v1/translation-projects/1032/',
      '/api/v1/translation-projects/1033/',
      '/api/v1/translation-projects/1034/',
      '/api/v1/translation-projects/1035/',
      '/api/v1/translation-projects/1036/',
      '/api/v1/translation-projects/1037/',
      '/api/v1/translation-projects/1038/',
      '/api/v1/translation-projects/1039/',
      '/api/v1/translation-projects/1040/',
      '/api/v1/translation-projects/1041/',
      '/api/v1/translation-projects/1042/',
      '/api/v1/translation-projects/1043/',
      '/api/v1/translation-projects/1044/',
      '/api/v1/translation-projects/1045/',
      '/api/v1/translation-projects/1046/',
      '/api/v1/translation-projects/1047/',
      '/api/v1/translation-projects/1048/',
      '/api/v1/translation-projects/1049/',
      '/api/v1/translation-projects/1050/',
      '/api/v1/translation-projects/1051/',
      '/api/v1/translation-projects/1052/',
      '/api/v1/translation-projects/1053/',
      '/api/v1/translation-projects/1054/',
      '/api/v1/translation-projects/1055/',
      '/api/v1/translation-projects/1056/',
      '/api/v1/translation-projects/1057/',
      '/api/v1/translation-projects/1058/',
      '/api/v1/translation-projects/1059/',
      '/api/v1/translation-projects/1060/',
      '/api/v1/translation-projects/1061/',
      '/api/v1/translation-projects/1062/',
      '/api/v1/translation-projects/1063/',
      '/api/v1/translation-projects/1064/',
      '/api/v1/translation-projects/1065/',
      '/api/v1/translation-projects/1066/',
      '/api/v1/translation-projects/1067/',
      '/api/v1/translation-projects/1068/',
      '/api/v1/translation-projects/1071/'
    ],
    'treestyle' => 'nongnu'
  });
  _runSimpleTests('projects', 24, 'project', '/api/v1/projects/23/', $expectedObject);
};

subtest "TranslationProjects", \&translationProjects;
sub translationProjects {
  my $expectedObject = Pootle::Resource::TranslationProject->new({
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
  });
  _runSimpleTests('translationProjects', 6, 'translationProject', '/api/v1/translation-projects/989/', $expectedObject);

=head2 SKIPPED WHEN USING MOCKED API
##Instead of spamming the _runSimpleTests(), we need to use exception handling here to catch an unsupported endpoint
##But only if using a live Pootle-Client to test

  my ($objs, $obj);
  eval {

  try {
    $objs = $papi->translationProjects();
    ok(0, "THIS SHOULD CRASH! GET /api/v1/translation-projects is unimplemeted");
  } catch {
    ok(blessed $_ && $_->isa('Pootle::Exception::HTTP::MethodNotAllowed'),
       "GET /api/v1/translation-projects is unimplemeted");
  };

  ok($obj = $papi->translationProject('/api/v1/translation-projects/989/'),
     "When a object is fetched");

  is_deeply($obj, $expectedObject,
     "Then the objects is as expected");

  };
  if ($@) {
    ok(0, $@);
  }
=cut
};

subtest "Stores", \&stores;
sub stores {
  my $expectedObject = Pootle::Resource::Store->new({
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
  });
  _runSimpleGetOnly('store', '/api/v1/stores/7578/', $expectedObject);
};

subtest "Units", \&units;
sub units {
  my $expectedObject = Pootle::Resource::Unit->new({
    'commented_on' => '2017-05-11T19:17:51',
    'context' => '',
    'developer_comment' => '',
    'locations' => 'intranet-tmpl/prog/en/xslt/MARC21slim2MODS32.xsl:946',
    'mtime' => '2017-06-16T00:45:09',
    'resource_uri' => '/api/v1/units/20043867/',
    'source_f' => 'tape cassette',
    'source_length' => 13,
    'source_wordcount' => 2,
    'state' => 200,
    'store' => '/api/v1/stores/7578/',
    'submitted_on' => '2017-05-11T19:17:51',
    'suggestions' => [],
    'target_f' => 'nauhakasetti',
    'target_length' => 12,
    'target_wordcount' => 1,
    'translator_comment' => ''
  });
  _runSimpleGetOnly('unit', '/api/v1/units/20043867/', $expectedObject);
};

done_testing();



sub _runSimpleTests($pluralMethod, $totalCount, $singularMethod, $singularUri, $expectedObject) {
  my ($objs, $obj);
  eval {

  ok($objs = $papi->$pluralMethod(),
     "When all objects are fetched");

  is(@$objs, $totalCount,
     "Then we found $totalCount objects in total");

  _runSimpleGetOnly($singularMethod, $singularUri, $expectedObject);

  };
  if ($@) {
    ok(0, $@);
  }
}

sub _runSimpleGetOnly($singularMethod, $singularUri, $expectedObject) {
  my ($obj);
  eval {

  ok($obj = $papi->$singularMethod($singularUri),
     "When a object is fetched");

  is_deeply($obj, $expectedObject,
     "Then the objects is as expected");

  };
  if ($@) {
    ok(0, $@);
  }
}
