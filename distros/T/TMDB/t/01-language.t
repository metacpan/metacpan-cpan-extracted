#!perl

####################
# LOAD CORE MODULES
####################
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::MockObject;
use TMDB;
use HTTP::Tiny;

# Autoflush ON
local $| = 1;


my $mock = Test::MockObject->new;
$mock->set_isa('HTTP::Tiny');
$mock->set_always( 
    'get',
    {   success => 1,
        status => 200,
        headers => {},
        content => '{ "id": 1234, "results": [], "changes": [], "title": "blabla", "name": "blabla", "overview": "blabla blabla", "credits": { "cast": [], "crew": [] }}'
    }
);

my $tmdb = TMDB->new( apikey => 'fake-api-key', lang => 'es', client => $mock);

my $show = $tmdb->tv(id => 1234);
my ($name, $args, $url);

# Tests language parameters for Session:talk requests
my $session = $tmdb->{session};

$mock->clear;
$session->talk( { method => "test/path", params => { para1 => "v1", para2 => "v2" } } );
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $session->talk may be localized' );

$mock->clear;
$session->talk( { method => "test/path", params => { para1 => "v1", para2 => "v2", language => "fr" } } );
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=fr(&|$)/, 'Request $session->talk language parameter overrides default language' );

# Tests language parameters for TV Show requests
$mock->clear;
$show->info;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->info may be localized' );

$mock->clear;
$show->similar(1);
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->similar may be localized' );

$mock->clear;
$show->season(1);
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->season(1) may be localized' );

$mock->clear;
$show->episode(1,2);
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->episode(1,2) may be localized' );

$mock->clear;
$show->cast;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->cast may be localized' );

$mock->clear;
$show->crew;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->crew may be localized' );

$mock->clear;
$show->images;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->images may be localized' );

$mock->clear;
$show->videos;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->videos may be localized' );

$mock->clear;
$show->version;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->version may be localized' );

$mock->clear;
$show->_credits;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->_credits may be localized' );

SKIP: {
    skip "Requests that don't use language", 4;

    $mock->clear;
    $show->alternative_titles;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->alternative_titles may be localized' );

    $mock->clear;
    $show->translations;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->translations may be localized' );

    $mock->clear;
    $show->content_ratings;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->content_ratings may be localized' );

    $mock->clear;
    $show->keywords;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->keywords may be localized' );
};

SKIP: {
    skip "Requests not implemented", 10;

    $mock->clear;
    $show->aggregate_credits;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->aggregate_credits may be localized' );

    $mock->clear;
    $show->changes;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->changes may be localized' );

    $mock->clear;
    $show->credits;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->credits may be localized' );

    $mock->clear;
    $show->episode_groups;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->episode_groups may be localized' );

    $mock->clear;
    $show->external_ids;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->external_ids may be localized' );

    $mock->clear;
    $show->recommendations;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->recommendations may be localized' );

    $mock->clear;
    $show->lists;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->lists may be localized' );

    $mock->clear;
    $show->reviews;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->reviews may be localized' );

    $mock->clear;
    $show->screened_theatrically;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->screened_theatrically may be localized' );

    $mock->clear;
    $show->watch_providers;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $show->watch_providers may be localized' );
};

# Tests language parameters for Movie requests
my $movie = $tmdb->movie(id => 1234);

$mock->clear;
$movie->info;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->info may be localized' );

$mock->clear;
$movie->similar(1);
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->similar may be localized' );

$mock->clear;
$movie->lists(1);
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->lists may be localized' );

$mock->clear;
$movie->reviews(1);
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->reviews may be localized' );

$mock->clear;
$movie->title;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->title may be localized' );

$mock->clear;
$movie->year;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->year may be localized' );

$mock->clear;
$movie->tagline;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->tagline may be localized' );

$mock->clear;
$movie->overview;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->overview may be localized' );

$mock->clear;
$movie->imdb_id;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->imdb_id may be localized' );

$mock->clear;
$movie->description;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->description may be localized' );

$mock->clear;
$movie->collection;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->collection may be localized' );

$mock->clear;
$movie->genres;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->genres may be localized' );

$mock->clear;
$movie->homepage;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->homepage may be localized' );

$mock->clear;
$movie->studios;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->studios may be localized' );

$mock->clear;
$movie->poster;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->poster may be localized' );

$mock->clear;
$movie->backdrop;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->backdrop may be localized' );

$mock->clear;
$movie->cast;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->cast may be localized' );

$mock->clear;
$movie->crew;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->crew may be localized' );

$mock->clear;
$movie->images;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->images may be localized' );

$mock->clear;
$movie->trailers;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->trailers may be localized' );

$mock->clear;
$movie->version;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->version may be localized' );

$mock->clear;
$movie->actors;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->actors may be localized' );

$mock->clear;
$movie->director;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->director may be localized' );

$mock->clear;
$movie->producer;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->producer may be localized' );

$mock->clear;
$movie->executive_producer;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->executive_producer may be localized' );

$mock->clear;
$movie->writer;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->writer may be localized' );

$mock->clear;
$movie->posters;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->posters may be localized' );

$mock->clear;
$movie->backdrops;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->backdrops may be localized' );

$mock->clear;
$movie->trailers_youtube;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->trailers_youtube may be localized' );

$mock->clear;
$movie->_cast;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->_cast may be localized' );

$mock->clear;
$movie->_crew_names;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->_crew_names may be localized' );

SKIP: {
    skip "Requests that don't use language", 5;

    $mock->clear;
    $movie->alternative_titles;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->alternative_titles may be localized' );

    $mock->clear;
    $movie->changes;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->changes may be localized' );

    $mock->clear;
    $movie->keywords;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->keywords may be localized' );

    $mock->clear;
    $movie->releases;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->releases may be localized' );

    $mock->clear;
    $movie->translations;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->translations may be localized' );
};

SKIP: {
    skip "Requests not implemented", 6;

    $mock->clear;
    $movie->credits;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->credits may be localized' );

    $mock->clear;
    $movie->external_ids;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->external_ids may be localized' );

    $mock->clear;
    $movie->recommendations;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->recommendations may be localized' );

    $mock->clear;
    $movie->release_dates;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->release_dates may be localized' );

    $mock->clear;
    $movie->videos;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->videos may be localized' );

    $mock->clear;
    $movie->watch_providers;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $movie->watch_providers may be localized' );
};

# Tests language parameters for Collection requests
my $collection = $tmdb->collection(id => 1234);

$mock->clear;
$collection->info;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $collection->info may be localized' );

$mock->clear;
$collection->ids;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $collection->ids may be localized' );

$mock->clear;
$collection->titles;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $collection->titles may be localized' );

$mock->clear;
$collection->_parse_parts;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $collection->_parse_parts may be localized' );

$mock->clear;
$collection->version;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $collection->version may be localized' );

SKIP: {
    skip "Not implemented", 2;

    $mock->clear;
    $collection->images;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $collection->images may be localized' );

    $mock->clear;
    $collection->translations;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $collection->translations may be localized' );
};

# Tests language parameters for company requests
my $company = $tmdb->company(id => 1234);

SKIP: {
    skip "Requests that don't use language", 6;

    $mock->clear;
    $company->info;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $company->info may be localized' );

    $mock->clear;
    $company->version;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $company->version may be localized' );

    $mock->clear;
    $company->movies;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $company->movies may be localized' );

    $mock->clear;
    $company->name;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $company->name may be localized' );

    $mock->clear;
    $company->logo;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $company->logo may be localized' );

    $mock->clear;
    $company->image;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $company->image may be localized' );
};

# Tests language parameters for Genre requests
my $genre = $tmdb->genre(id => 1234);

$mock->clear;
$genre->list;    # localized by lang only
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $genre->list may be localized' );

$mock->clear;
$genre->movies;  # localized by only
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $genre->movies may be localized' );

# Tests language parameters for Configuration requests
$mock->clear;
my $configuration = $tmdb->config;

SKIP: {
    skip "Configuration creation don't use language", 1;

    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Configuration creation may be localized' );
};

SKIP: {
    skip "Requests not implemented", 5;

    $mock->clear;
    $configuration->countries;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $configuration->countries may be localized' );

    $mock->clear;
    $configuration->jobs;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $configuration->jobs may be localized' );

    $mock->clear;
    $configuration->languages;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $configuration->languages may be localized' );

    $mock->clear;
    $configuration->primary_translations;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $configuration->primary_translations may be localized' );

    $mock->clear;
    $configuration->timezones;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $configuration->timezones may be localized' );
};

# Tests language parameters for Person requests
my $person = $tmdb->person(id => 1234);

$mock->clear;
$person->info;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $person->info may be localized' );

$mock->clear;
$person->version;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $person->version may be localized' );

$mock->clear;
$person->name;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $person->name may be localized' );

$mock->clear;
$person->aka;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $person->aka may be localized' );

$mock->clear;
$person->bio;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $person->bio may be localized' );

$mock->clear;
$person->image;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $person->image may be localized' );

$mock->clear;
$person->credits;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $person->credits may be localized' );

$mock->clear;
$person->starred_in;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $person->starred_in may be localized' );

$mock->clear;
$person->directed;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $person->directed may be localized' );

$mock->clear;
$person->produced;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $person->produced may be localized' );

$mock->clear;
$person->executive_produced;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $person->executive_produced may be localized' );

$mock->clear;
$person->wrote;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $person->wrote may be localized' );

$mock->clear;
$person->_crew_names;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $person->_crew_names may be localized' );

SKIP: {
    skip "Requests that don't use language", 1;

    $mock->clear;
    $person->images;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $person->images may be localized' );
};

SKIP: {
    skip "Requests not implemented", 6;

    $mock->clear;
    $person->changes;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $person->changes may be localized' );

    $mock->clear;
    $person->combined_credits;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $person->combined_credits may be localized' );

    $mock->clear;
    $person->movie_credits;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $person->movie_credits may be localized' );

    $mock->clear;
    $person->tv_credits;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $person->tv_credits may be localized' );

    $mock->clear;
    $person->tagged_images;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $person->tagged_images may be localized' );

    $mock->clear;
    $person->translations;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $person->translations may be localized' );
};

# Tests language parameters for Person requests
my $search = $tmdb->search();

$mock->clear;
$search->movie("Test");
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $search->movie may be localized' );

$mock->clear;
$search->tv("Test");
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $search->tv may be localized' );

$mock->clear;
$search->upcoming;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $search->upcoming may be localized' );

$mock->clear;
$search->now_playing;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $search->now_playing may be localized' );

$mock->clear;
$search->popular;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $search->popular may be localized' );

$mock->clear;
$search->popular_people;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $search->popular_people may be localized' );

$mock->clear;
$search->discover;
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $search->discover may be localized' );

$mock->clear;
$search->find( id =>"id", source => "source");
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $search->find may be localized' );

$mock->clear;
$search->person("Test");
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $search->person may be localized' );

$mock->clear;
$search->collection("Test");
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $search->collection may be localized' );

$mock->clear;
$search->list("Test");
($name, $args) = $mock->next_call();
$url = @$args[1];
ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $search->list may be localized' );

SKIP: {
    skip "Requests that don't use language", 4;

    $mock->clear;
    $search->company("Test");
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $search->company may be localized' );

    $mock->clear;
    $search->keyword("Test");
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $search->keyword may be localized' );

    $mock->clear;
    $search->latest;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $search->latest may be localized' );

    $mock->clear;
    $search->latest_person;
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $search->latest_person may be localized' );
};

SKIP: {
    skip "Requests not implemented", 1;

    $mock->clear;
    $search->multi("Test");
    ($name, $args) = $mock->next_call();
    $url = @$args[1];
    ok( $url =~ /(&|\?)language=es(&|$)/, 'Request $search->multi may be localized' );
};


# Done
done_testing(125);
exit 0;
