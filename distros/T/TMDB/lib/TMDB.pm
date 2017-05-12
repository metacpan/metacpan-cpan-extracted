package TMDB;

#######################
# LOAD MODULES
#######################
use strict;
use warnings FATAL => 'all';
use Carp qw(croak carp);

#######################
# VERSION
#######################
our $VERSION = '1.2.1';

#######################
# LOAD CPAN MODULES
#######################
use Object::Tiny qw(session);

#######################
# LOAD DIST MODULES
#######################
use TMDB::Genre;
use TMDB::Movie;
use TMDB::TV;
use TMDB::Config;
use TMDB::Person;
use TMDB::Search;
use TMDB::Company;
use TMDB::Session;
use TMDB::Collection;

#######################
# PUBLIC METHODS
#######################

## ====================
## CONSTRUCTOR
## ====================
sub new {
    my ( $class, @args ) = @_;
    my $self = {};
    bless $self, $class;

    # Init Session
    $self->{session} = TMDB::Session->new(@args);
  return $self;
} ## end sub new

## ====================
## TMDB OBJECTS
## ====================
sub collection {
  return TMDB::Collection->new(
        session => shift->session,
        @_
    );
} ## end sub collection
sub company { return TMDB::Company->new( session => shift->session, @_ ); }
sub config { return TMDB::Config->new( session => shift->session, @_ ); }
sub genre { return TMDB::Genre->new( session => shift->session, @_ ); }
sub movie { return TMDB::Movie->new( session => shift->session, @_ ); }
sub tv { return TMDB::TV->new( session => shift->session, @_ ); }
sub person { return TMDB::Person->new( session => shift->session, @_ ); }
sub search { return TMDB::Search->new( session => shift->session, @_ ); }

#######################
1;

__END__

#######################
# POD SECTION
#######################

=pod

=head1 NAME

TMDB - Perl wrapper for The MovieDB API

=head1 SYNOPSIS

      use TMDB;

      # Initialize
      my $tmdb = TMDB->new( apikey => 'xxxxxxxxxx' );

      # Search
      # =======

      # Search for a movie
      my @results = $tmdb->search->movie('Snatch');
      foreach my $result (@results) {
        printf( "%s:\t%s (%s)\n",
            $result->{id}, $result->{title},
            split( /-/, $result->{release_date}, 1 ) );
      }

      # Search for an actor
      my @results = $tmdb->search->person('Sean Connery');
      foreach my $result (@results) {
        printf( "%s:\t%s\n", $result->{id}, $result->{name} );
      }

      # Search for a TV show
      my @results = $tmdb->search->tv('The Big Bang Theory');
      foreach my $result (@results) {
        printf( "%s:\t%s (%s)\n",
            $result->{id}, $result->{name},
            split( /-/, $result->{first_air_date}, 1 ) );
      }

      # Movie Data
      # ===========

      # Movie Object
      my $movie = $tmdb->movie( id => '107' );

      # Movie details
      my $movie_title     = $movie->title;
      my $movie_year      = $movie->year;
      my $movie_tagline   = $movie->tagline;
      my $movie_overview  = $movie->overview;
      my $movie_website   = $movie->homepage();
      my @movie_directors = $movie->director;
      my @movie_actors    = $movie->actors;
      my @studios         = $movie->studios;

      printf( "%s (%s)\n%s", $movie_title, $movie_year,
        '=' x length($movie_title) );
      printf( "Tagline: %s\n",     $movie_tagline );
      printf( "Overview: %s\n",    $movie_overview );
      printf( "Directed by: %s\n", join( ',', @movie_directors ) );
      print("\nCast:\n");
      printf( "\t-%s\n", $_ ) for @movie_actors;

      # Person Data
      # ===========

      # Person Object
      my $person = $tmdb->person( id => '1331' );

      # Person Details
      my $person_name   = $person->name;
      my $person_bio    = $person->bio;
      my @person_movies = $person->starred_in;

      printf( "%s\n%s\n%s\n",
        $person_name, '=' x length($person_name), $person_bio );
      print("\nActed in:\n");
      printf( "\t-%s\n", $_ ) for @person_movies;

      # TV Show Data
      # ===========

      # TV Show Object
      my $show = $tmdb->tv( id => '1418' );

      my $season = $show->season(5);
      my $episode = $show->episode(2, 3);


=head1 DESCRIPTION

L<The MovieDB|http://www.themoviedb.org/> is a free and open movie
database. This module provides a Perl wrapper to L<The MovieDB
API|http://docs.themoviedb.apiary.io/>. In order to use this module,
you must first get an API key by L<signing
up|http://www.themoviedb.org/account/signup>.

B<NOTE:> TMDB-v0.04 and higher uses TheMoviDB API version C</3>. This
brings some significant differences both to the API and the interface
this module provides, along with updated dependencies for this
distribution. If you like to continue to use v2.1 API, you can continue
to use L<TMDB-0.03x|https://metacpan.org/release/MITHUN/TMDB-0.03/>.

=head1 INITIALIZATION

      # Initialize
      my $tmdb = TMDB->new(
         apikey => 'xxxxxxxxxx...',  # API Key
         lang   => 'en',             # A valid ISO 639-1 (Aplha-2) language code
         client => $http_tiny,       # A valid HTTP::Tiny object
         json   => $json_object,     # A Valid JSON object
      );

The constructor accepts the following options:

=over

=item apikey

This is your API key

=item lang

This must be a valid ISO 639-1 (Alpha-2) language code. Note that with
C</3>, the API no longer falls back to an English default.

L<List of ISO 639-1
codes|http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes>.

=item client

You can provide your own L<HTTP::Tiny> object, otherwise a default one
is used.

=item json

You can provide your own L<JSON> implementation that can C<decode>
JSON. This will fall back to using L<JSON::MaybeXS>. However,
L<JSON::XS> is recommended.

=item apiurl

The API endpoint to use. Defaults to L<https://api.themoviedb.org/3>

=back

=head1 CONFIGURATION

      # Get Config
      my $config = $tmdb->config;
      print Dumper $config->config;   # Get all of it

      # Get the base URL
      my $base_url        = $config->img_base_url();
      my $secure_base_url = $config->img_secure_base_url();

      # Sizes (All are array-refs)
      my $poster_sizes   = $config->img_poster_sizes();
      my $backdrop_sizes = $config->img_backdrop_sizes();
      my $profile_sizes  = $config->img_profile_sizes();
      my $logo_sizes     = $config->img_logo_sizes();

      # List of _change keys_
      my $change_keys = $config->change_keys();

This provides the configuration for the C</3> API. See
L<http://docs.themoviedb.apiary.io/#configuration> for more details.

=head1 SEARCH

      # Configuration
      my $search = $tmdb->search(
         include_adult => 'false',  # Include adult results. 'true' or 'false'
         max_pages     => 5,        # Max number of paged results
      );

      # Search
      my $search  = $tmdb->search();
      my @results = $search->movie('Snatch (2000)');          # Search for movies
      my @results = $search->tv('The Big Bang Theory (2007)') # Search for TV shows
      my @results = $search->person('Brad Pitt');             # Search people by Name
      my @results = $search->company('Sony Pictures');        # Search for companies
      my @results = $search->keyword('thriller');             # Search for keywords
      my @results = $search->collection('Star Wars');         # Search for collections
      my @results = $search->list('top 250');                 # Search lists

      # Find using external sources
      my @results = $search->find(
          id     => 'tt12345',
          source => 'imdb_id'
      );

      # Discover
      my @results = $search->discover(
          {
              sort_by            => 'popularity.asc',
              'vote_average.gte' => '7.2',
              'vote_count.gte'   => '10',
          }
      );

      # Get Lists
      my $lists         = $tmdb->search();
      my $latest        = $lists->latest();      # Latest movie added to TheMovieDB
      my $latest_person = $lists->latest_person; # Latest person added to TheMovieDB
      my @now_playing   = $lists->now_playing(); # What's currently in theaters
      my @upcoming      = $lists->upcoming();    # Coming soon ...
      my @popular       = $lists->popular();     # What's currently popular
      my @popular_people = $lists->popular_people();  # Who's currently popular
      my @top_rated      = $lists->top_rated();       # Get the top rated list


=head1 MOVIE

      # Get the movie object
      my $movie = $tmdb->movie( id => '49521' );

      # Movie Data (as returned by the API)
      use Data::Dumper qw(Dumper);
      print Dumper $movie->info;
      print Dumper $movie->alternative_titles;
      print Dumper $movie->cast;
      print Dumper $movie->crew;
      print Dumper $movie->images;
      print Dumper $movie->keywords;
      print Dumper $movie->releases;
      print Dumper $movie->trailers;
      print Dumper $movie->translations;
      print Dumper $movie->lists;
      print Dumper $movie->reviews;
      print Dumper $movie->changes;

      # Filtered Movie data
      print $movie->title;
      print $movie->year;
      print $movie->tagline;
      print $movie->overview;
      print $movie->description;         # Same as `overview`
      print $movie->genres;
      print $movie->imdb_id;
      print $movie->collection;          # Collection ID
      print $movie->actors;              # Names of Actors
      print $movie->director;            # Names of Directors
      print $movie->producer;            # Names of Producers
      print $movie->executive_producer;  # Names of Executive Producers
      print $movie->writer;              # Names of Writers/Screenplay

      # Images
      print $movie->poster;              # Main Poster
      print $movie->posters;             # list of posters
      print $movie->backdrop;            # Main backdrop
      print $movie->backdrops;           # List of backdrops
      print $movie->trailers_youtube;    # List of Youtube trailers URLs

      # Latest Movie on TMDB
      print Dumper $movie->latest;

      # Get TMDB's version to check if anything changed
      print $movie->version;


=head1 PEOPLE

      # Get the person object
      my $person = $tmdb->person( id => '1331' );

      # Movie Data (as returned by the API)
      use Data::Dumper qw(Dumper);
      print Dumper $person->info;
      print Dumper $person->credits;
      print Dumper $person->images;

      # Filtered Person data
      print $person->name;
      print $person->aka;                 # Also Known As (list of names)
      print $person->bio;
      print $person->image;               # Main profile image
      print $person->starred_in;          # List of titles (as cast)
      print $person->directed;            # list of titles Directed
      print $person->produced;            # list of titles produced
      print $person->executive_produced;  # List of titles as an Executive Producer
      print $person->wrote;               # List of titles as a writer/screenplay

      # Get TMDB's version to check if anything changed
      print $person->version;


=head1 COLLECTION

      # Get the collection object
      my $collection = $tmdb->collection(id => '2344');

      # Collection data (as returned by the API)
      use Data::Dumper;
      print Dumper $collection->info;

      # Filtered Collection Data
      print $collection->titles;  # List of titles in the collection
      print $collection->ids;     # List of movie IDs in the collection

      # Get TMDB's version to check if anything changed
      print $collection->version;


=head1 COMPANY

      # Get the company object
      my $company = $tmdb->company(id => '1');

      # Company info (as returned by the API)
      use Data::Dumper qw(Dumper);
      print Dumper $company->info;
      print Dumper $company->movies;

      # Filtered company data
      print $company->name; # Name of the Company
      print $company->logo; # Logo

      # Get TMDB's version to check if anything changed
      print $company->version;

=head1 GENRE

      # Get a list
      my @genres = $tmdb->genre->list();

      # Get a list of movies
      my @movies = $tmdb->genre(id => '35')->movies;

=head1 TV SHOW

      # Get the TV show object
      my $show = $tmdb->tv( id => '1418' );

      # TV Show Data (as returned by the API)
      use Data::Dumper qw(Dumper);
      print Dumper $show->info;
      print Dumper $show->alternative_titles;
      print Dumper $show->cast;
      print Dumper $show->crew;
      print Dumper $show->images;
      print Dumper $show->keywords;
      print Dumper $show->videos;
      print Dumper $show->translations;
      print Dumper $show->content_ratings;
      print Dumper $show->changes;

      # Get Season and Episode info
      print Dumper $show->season(5);
      print Dumper $show->episode(1, 1);

      # Get TMDB's version to check if anything changed
      print $show->version;


=head1 DEPENDENCIES

=over

=item L<Encode>

=item L<HTTP::Tiny>

=item L<JSON::MaybeXS>

=item L<Locale::Codes>

=item L<Object::Tiny>

=item L<Params::Validate>

=item L<URI::Encode>

=back

=head1 BUGS AND LIMITATIONS

This module not (yet!) support POST-ing data to TheMovieDB

All data returned is UTF-8 encoded

Please report any bugs or feature requests at
L<https://github.com/mithun/perl-tmdb/issues>

=head1 SEE ALSO

=over

=item L<The MovieDB API|http://docs.themoviedb.apiary.io/>

=item L<API Support|https://www.themoviedb.org/talk/category/5047958519c29526b50017d6>

=item L<WWW::TMDB::API>

=back

=head1 AUTHOR

Mithun Ayachit C<mithun@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015, Mithun Ayachit. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.

=cut
