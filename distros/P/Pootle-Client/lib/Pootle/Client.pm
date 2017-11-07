# Copyright (C) 2017 Koha-Suomi
#
# This file is part of Pootle::Client.

package Pootle::Client;

use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use feature 'signatures'; no warnings "experimental::signatures";
use Carp::Always;
use Try::Tiny;
use Scalar::Util qw(blessed);

our $VERSION = '0.07';

=head1 Pootle::Client

Client to talk with Pootle API v1 nicely

See.
    https://pootle.readthedocs.io/en/stable-2.5.1/api/index.html
for more information about the API resources/data_structures this Client returns.

Eg. https://pootle.readthedocs.io/en/stable-2.5.1/api/api_project.html#get-a-project
maps to Pootle::Resource::Project locally.

=head1 REQUIRES

Perl 5.20 or newer with support for subroutine signatures

=head2 Caches

See L<Pootle::Cache>, for how the simple caching system works to spare the Pootle-Server from abuse

=head2 Logger

See L<Pootle::Logger>, for how to change Pootle::Client chattiness

=head1 Synopsis

    my $papi = Pootle::Client->new({
                  baseUrl => 'http://translate.example.com',
                  credentials => 'username:password' || 'credentials.txt'}
    );
    my $languages = $papi->languages();
    my $trnsProjs = $papi->searchTranslationProjects(
                       $languages,
                       Pootle::Filters->new({fullname => qr/^Project name/})
    );


=cut

use Params::Validate qw(:all);

use Pootle::Agent;
use Pootle::Cache;
use Pootle::Filters;
use Pootle::Resource::Language;
use Pootle::Resource::TranslationProject;
use Pootle::Resource::Store;
use Pootle::Resource::Unit;
use Pootle::Resource::Project;

use Pootle::Logger;
my $l = bless({}, 'Pootle::Logger'); #Lazy load package logger this way to avoid circular dependency issues with logger includes from many packages

=head2 new($params)

Instantiates a new Pootle::Client

 $params HASHRef of parameters {
           baseUrl => 'http://translate.pootle.url',
           credentials => 'usename:password' ||
                          'credentials.file.containing.credentials.txt',
           cacheFile => 'pootle-client.cache',
         }

 @returns Pootle::Client

=cut

sub new($class, @params) {
  $l->debug("Initializing '$class' with parameters: ".$l->flatten(@params)) if $l->is_debug();
  my %self = validate(@params, {
    baseUrl       => 1, #Passed to Pootle::Agent
    credentials   => 1, #Passed to Pootle::Agent
    cacheFile     => 0, #Passed to Pootle::Cache
  });
  my $s = bless(\%self, $class);

  $s->{agent} = new Pootle::Agent({baseUrl => $s->{baseUrl}, credentials => $s->{credentials}});
  $s->{cache} = new Pootle::Cache({cacheFile => $s->{cacheFile}});

  return $s;
}

=head1 ACCESSING THE POOTLE API

This Client transparently handles authentication based on the credentials supplied.
Use the following methods to make API requests.

=item language

 @PARAM1  String, API endpoint to get the resource, eg. /api/v1/languages/124/
 @RETURNS L<Pootle::Resource::Language>

=cut

sub language($s, $endpoint) {
  $l->info("getting language $endpoint");
  my $contentHash = $s->a->request('get', $endpoint, {});
  return new Pootle::Resource::Language($contentHash);
}

=item languages

 @RETURNS ARRAYRef of L<Pootle::Resource::Language>,
                                           all languages in the Pootle database
 @CACHED  Transiently

=cut

sub languages($s) {
  if (my $cached = $s->c->tGet('/api/v1/languages/')) {
    $l->info("getting languages from cache");
    return $cached;
  }
  $l->info("getting languages");

  my $contentHash = $s->a->request('get', '/api/v1/languages/', {});
  my $objs = $contentHash->{objects};
  for (my $i=0 ; $i<@$objs ; $i++) {
    $objs->[$i] = new Pootle::Resource::Language($objs->[$i]);
  }
  $s->c->tSet('/api/v1/languages/', $objs);
  return $objs;
}

=item findLanguages

Uses the API to find all languages starting with the given country code

 @PARAM1  L<Pootle::Filters>
 @RETURNS ARRAYRef of L<Pootle::Resource::Language>,
          all languages starting with the given code.
 @CACHED  Persistently

=cut

sub findLanguages($s, $filters) {
  if (my $cached = $s->c->pGet('findLanguages '.$l->flatten($filters))) {
    $l->info("finding languages from cache");
    return $cached if $cached;
  }
  $l->info("finding languages");

  my $objects = $filters->filter( $s->languages() );

  $s->c->pSet('findLanguages '.$l->flatten($filters), $objects);
  return $objects;
}

=item translationProject

 @PARAM1  String, API endpoint to get the resource,
          eg. /api/v1/translation-projects/124/
 @RETURNS L<Pootle::Resource::TranslationProject>

=cut

sub translationProject($s, $endpoint) {
  $l->info("getting translation project $endpoint");
  my $contentHash = $s->a->request('get', $endpoint, {});
  return new Pootle::Resource::TranslationProject($contentHash);
}

=item translationProjects

 @UNIMPLEMENTED

This endpoint is unimplemented in the Pootle-Client. Maybe some day it becomes enabled. If it does, this should work out-of-box.

It might be better to use searchTranslationProjects() instead, since this API call can be really invasive to the Pootle-server.
Really depends on how many translation projects you are after.

 @RETURNS ARRAYRef of L<Pootle::Resource::TranslationProject>,
          all translation projects in the Pootle database
 @CACHED  Transiently
 @THROWS  L<Pootle::Exception::HTTP::MethodNotAllowed>

=cut

sub translationProjects($s) {
  if (my $cache = $s->c->tGet('/api/v1/translation-projects/')) {
    $l->info("getting translation projects from cache");
    return $cache;
  }
  $l->info("getting translation projects");

  my $contentHash = $s->a->request('get', '/api/v1/translation-projects/', {});
  my $objs = $contentHash->{objects};
  for (my $i=0 ; $i<@$objs ; $i++) {
    $objs->[$i] = new Pootle::Resource::TranslationProject($objs->[$i]);
  }
  $s->c->tSet('/api/v1/translation-projects/', $objs);
  return $objs;
}

=item findTranslationProjects

 @UNIMPLEMENTED

This endpoint is unimplemented in the Pootle-Client. Maybe some day it becomes enabled. If it does, this should work out-of-box.

Uses the API to find all translation projects matching the given search expressions

 @PARAM1  L<Pootle::Filters>, Used to select the desired objects
 @RETURNS ARRAYRef of L<Pootle::Resource::TranslationProject>.
          All matched translation projects.
 @CACHED  Persistently
 @THROWS  L<Pootle::Exception::HTTP::MethodNotAllowed>

=cut

sub findTranslationProjects($s, $filters) {
  if (my $cached = $s->c->pGet('findTranslationProjects '.$l->flatten($filters))) {
    $l->info("finding translation projects from cache");
    return $cached;
  }
  $l->info("finding translation projects");

  my $objects = $filters->filter( $s->translationProjects() );

  $s->c->pSet('findTranslationProjects '.$l->flatten($filters), $objects);
  return $objects;
}

=item searchTranslationProjects

 @PARAM1  L<Pootle::Filters>, Filters to pick desired languages
          or
          ARRAYRef of L<Pootle::Resource::Language>
 @PARAM2  L<Pootle::Filters>, Filters to pick desired projects
          or
          ARRAYRef of L<Pootle::Resource::Project>
 @RETURNS ARRAYRef of L<Pootle::Resource::TranslationProject>,
          matching the given languages and projects
 @CACHED  Persistently

=cut

sub searchTranslationProjects($s, $languageFilters, $projectFilters) {
  if (my $cached = $s->c->pGet('searchTranslationProjects '.$l->flatten($languageFilters).$l->flatten($projectFilters))) {
    $l->info("searching translation projects from cache");
    return $cached;
  }
  $l->info("searching translation projects");

  my $languages;
  if (ref($languageFilters) eq 'ARRAY' && blessed($languageFilters->[0]) && $languageFilters->[0]->isa('Pootle::Resource::Language')) {
    $languages = $languageFilters;
  }
  else {
    $languages = $s->findLanguages($languageFilters);
  }

  my $projects;
  if (ref($projectFilters) eq 'ARRAY' && blessed($projectFilters->[0]) && $projectFilters->[0]->isa('Pootle::Resource::Project')) {
    $projects = $projectFilters;
  }
  else {
    $projects = $s->findProjects($projectFilters);
  }

  my $sharedTranslationProjectsEndpoints = Pootle::Filters->new()->intersect($languages, $projects, 'translation_projects', 'translation_projects');
  my @translationProjects;
  foreach my $intersection (@$sharedTranslationProjectsEndpoints) {
    push(@translationProjects, $s->translationProject($intersection->attributeValue));
  }

  $s->c->pSet('searchTranslationProjects '.$l->flatten($languageFilters).$l->flatten($projectFilters), \@translationProjects);
  return \@translationProjects;
}

=item store

 @PARAM1  String, API endpoint to get the resource, eg. /api/v1/stores/77/
 @RETURNS L<Pootle::Resource::Store>

=cut

sub store($s, $endpoint) {
  $l->info("getting store $endpoint");
  my $contentHash = $s->a->request('get', $endpoint, {});
  return new Pootle::Resource::Store($contentHash);
}

=item searchStores

 @PARAM1  L<Pootle::Filters>, Filters to pick desired languages
          or
          ARRAYRef of L<Pootle::Resource::Language>
 @PARAM2  L<Pootle::Filters>, Filters to pick desired projects
          or
          ARRAYRef of L<Pootle::Resource::Project>
 @RETURNS ARRAYRef of L<Pootle::Resource::Store>,
          matching the given languages and projects

=cut

sub searchStores($s, $languageFilters, $projectFilters) {
  if (my $cached = $s->c->pGet('searchStores '.$l->flatten($languageFilters).$l->flatten($projectFilters))) {
    $l->info("searching stores from cache");
    return $cached;
  }
  $l->info("searching stores");

  my $transProjs = $s->searchTranslationProjects($languageFilters, $projectFilters);

  my @stores;
  foreach my $translationProject (@$transProjs) {
    foreach my $storeUri (@{$translationProject->stores}) {
      push(@stores, $s->store($storeUri));
    }
  }

  $s->c->pSet('searchStores '.$l->flatten($languageFilters).$l->flatten($projectFilters), \@stores);
  return \@stores;
}

=item project

 @PARAM1  String, API endpoint to get the project, eg. /api/v1/projects/124/
 @RETURNS L<Pootle::Resource::Project>

=cut

sub project($s, $endpoint) {
  $l->info("getting project $endpoint");
  my $contentHash = $s->a->request('get', $endpoint, {});
  return new Pootle::Resource::Project($contentHash);
}

=item projects

 @RETURNS ARRAYRef of L<Pootle::Resource::Project>,
          all projects in the Pootle database
 @CACHED  Transiently

=cut

sub projects($s) {
  if(my $cached = $s->c->tGet('/api/v1/projects/')) {
    $l->info("getting projects from cache");
    return $cached;
  }
  $l->info("getting projects");

  my $contentHash = $s->a->request('get', '/api/v1/projects/', {});
  my $objs = $contentHash->{objects};
  for (my $i=0 ; $i<@$objs ; $i++) {
    $objs->[$i] = new Pootle::Resource::Project($objs->[$i]);
  }
  $s->c->tSet('/api/v1/projects/', $objs);
  return $objs;
}

=item findProjects

Uses the API to find all projects matching the given search expressions

 @PARAM1  L<Pootle::Filters>, matching criteria for needed objects
 @RETURNS ARRAYRef of L<Pootle::Resource::Project>. All matched projects.
 @CACHED  Persistently

=cut

sub findProjects($s, $filters) {
  if (my $cached = $s->c->pGet('findProjects '.$l->flatten($filters))) {
    $l->info("finding projects from cache");
    return $cached;
  }
  $l->info("finding projects");

  my $objects = $filters->filter( $s->projects() );

  $s->c->pSet('findProjects '.$l->flatten($filters), $objects);
  return $objects;
}

=item unit

 @PARAM1  String, API endpoint to get the resource, eg. /api/v1/units/77/
 @RETURNS L<Pootle::Resource::Unit>

=cut

sub unit($s, $endpoint) {
  $l->info("getting unit $endpoint");
  my $contentHash = $s->a->request('get', $endpoint, {});
  return new Pootle::Resource::Unit($contentHash);
}



=head1 HELPERS

=item flushCaches

Flushes all caches

=cut

sub flushCaches($s) {
  $s->c->flushCaches();
}

=head1 ACCESSORS

=item a

 @RETURNS L<Pootle::Agent>

=cut

sub a($s) { return $s->{agent} }

=item c

 @RETURNS L<Pootle::Cache>

=cut

sub c($s) { return $s->{cache} }

1;
