package TMDB::Search;

#######################
# LOAD CORE MODULES
#######################
use strict;
use warnings FATAL => 'all';
use Carp qw(croak carp);

#######################
# LOAD CPAN MODULES
#######################
use Params::Validate qw(validate_with :types);
use Object::Tiny qw(session include_adult max_pages);

#######################
# LOAD DIST MODULES
#######################
use TMDB::Session;

#######################
# VERSION
#######################
our $VERSION = '1.2.1';

#######################
# PUBLIC METHODS
#######################

## ====================
## Constructor
## ====================
sub new {
    my $class = shift;
    my %opts  = validate_with(
        params => \@_,
        spec   => {
            session => {
                type => OBJECT,
                isa  => 'TMDB::Session',
            },
            include_adult => {
                type      => SCALAR,
                optional  => 1,
                default   => 'false',
                callbacks => {
                    'valid flag' =>
                      sub { lc $_[0] eq 'true' or lc $_[0] eq 'false' }
                },
            },
            max_pages => {
                type      => SCALAR,
                optional  => 1,
                default   => 1,
                callbacks => {
                    'integer' => sub { $_[0] =~ m{\d+} },
                },
            },
        },
    );

    my $self = $class->SUPER::new(%opts);
  return $self;
} ## end sub new

## ====================
## Search Movies
## ====================
sub movie {
    my ( $self, $string ) = @_;

    # Get Year
    my $year;
    if ( $string =~ m{.+\((\d{4})\)$} ) {
        $year = $1;
        $string =~ s{\($year\)$}{};
    } ## end if ( $string =~ m{.+\((\d{4})\)$})

    # Trim
    $string =~ s{(?:^\s+)|(?:\s+$)}{};

    # Search
    my $params = {
        query         => $string,
        include_adult => $self->include_adult,
    };
    $params->{language} = $self->session->lang if $self->session->lang;
    $params->{year} = $year if $year;

    warn "DEBUG: Searching for $string\n" if $self->session->debug;
  return $self->_search(
        {
            method => 'search/movie',
            params => $params,
        }
    );
} ## end sub movie

## ====================
## Search TV Shows
## ====================
sub tv {
    my ( $self, $string ) = @_;

    # Get Year
    my $year;
    if ( $string =~ m{.+\((\d{4})\)$} ) {
        $year = $1;
        $string =~ s{\($year\)$}{};
    } ## end if ( $string =~ m{.+\((\d{4})\)$})

    # Trim
    $string =~ s{(?:^\s+)|(?:\s+$)}{};

    # Search
    my $params = {
        query         => $string,
        include_adult => $self->include_adult,
    };
    $params->{language} = $self->session->lang if $self->session->lang;
    $params->{year} = $year if $year;

    warn "DEBUG: Searching for $string\n" if $self->session->debug;
  return $self->_search(
        {
            method => 'search/tv',
            params => $params,
        }
    );
} ## end sub tv

## ====================
## Search Person
## ====================
sub person {
    my ( $self, $string ) = @_;

    warn "DEBUG: Searching for $string\n" if $self->session->debug;
  return $self->_search(
        {
            method => 'search/person',
            params => {
                query => $string,
            },
        }
    );
} ## end sub person

## ====================
## Search Companies
## ====================
sub company {
    my ( $self, $string ) = @_;

    warn "DEBUG: Searching for $string\n" if $self->session->debug;
  return $self->_search(
        {
            method => 'search/company',
            params => {
                query => $string,
            },
        }
    );
} ## end sub company

## ====================
## Search Lists
## ====================
sub list {
    my ( $self, $string ) = @_;

    warn "DEBUG: Searching for $string\n" if $self->session->debug;
  return $self->_search(
        {
            method => 'search/list',
            params => {
                query => $string,
            },
        }
    );
} ## end sub list

## ====================
## Search Keywords
## ====================
sub keyword {
    my ( $self, $string ) = @_;

    warn "DEBUG: Searching for $string\n" if $self->session->debug;
  return $self->_search(
        {
            method => 'search/keyword',
            params => {
                query => $string,
            },
        }
    );
} ## end sub keyword

## ====================
## Search Collection
## ====================
sub collection {
    my ( $self, $string ) = @_;

    warn "DEBUG: Searching for $string\n" if $self->session->debug;
  return $self->_search(
        {
            method => 'search/collection',
            params => {
                query => $string,
            },
        }
    );
} ## end sub collection

## ====================
## LISTS
## ====================

# Latest
sub latest { return shift->session->talk( { method => 'movie/latest', } ); }

# Upcoming
sub upcoming {
    my ($self) = @_;
  return $self->_search(
        {
            method => 'movie/upcoming',
            params => {
                language => $self->session->lang
                ? $self->session->lang
                : undef,
            },
        }
    );
} ## end sub upcoming

# Now Playing
sub now_playing {
    my ($self) = @_;
  return $self->_search(
        {
            method => 'movie/now-playing',
            params => {
                language => $self->session->lang
                ? $self->session->lang
                : undef,
            },
        }
    );
} ## end sub now_playing

# Popular
sub popular {
    my ($self) = @_;
  return $self->_search(
        {
            method => 'movie/popular',
            params => {
                language => $self->session->lang
                ? $self->session->lang
                : undef,
            },
        }
    );
} ## end sub popular

# Top rated
sub top_rated {
    my ($self) = @_;
  return $self->_search(
        {
            method => 'movie/top-rated',
            params => {
                language => $self->session->lang
                ? $self->session->lang
                : undef,
            },
        }
    );
} ## end sub top_rated

# Popular People
sub popular_people {
    my ($self) = @_;
  return $self->_search(
        {
            method => 'person/popular',
            params => {
                language => $self->session->lang
                ? $self->session->lang
                : undef,
            },
        }
    );
} ## end sub popular_people

# Latest Person
sub latest_person {
  return shift->session->talk(
        {
            method => 'person/latest',
        }
    );
} ## end sub latest_person

#######################
# DISCOVER
#######################
sub discover {
    my ( $self, @args ) = @_;
    my %options = validate_with(
        params => [@args],
        spec   => {
            sort_by => {
                type      => SCALAR,
                optional  => 1,
                default   => 'popularity.asc',
                callbacks => {
                    'valid flag' => sub {
                             ( lc $_[0] eq 'vote_average.desc' )
                          or ( lc $_[0] eq 'vote_average.asc' )
                          or ( lc $_[0] eq 'release_date.desc' )
                          or ( lc $_[0] eq 'release_date.asc' )
                          or ( lc $_[0] eq 'popularity.desc' )
                          or ( lc $_[0] eq 'popularity.asc' );
                    },
                },
            },
            year => {
                type     => SCALAR,
                optional => 1,
                regex    => qr/^\d{4}$/
            },
            primary_release_year => {
                type     => SCALAR,
                optional => 1,
                regex    => qr/^\d{4}$/
            },
            'release_date.gte' => {
                type     => SCALAR,
                optional => 1,
                regex    => qr/^\d{4}\-\d{2}\-\d{2}$/
            },
            'release_date.lte' => {
                type     => SCALAR,
                optional => 1,
                regex    => qr/^\d{4}\-\d{2}\-\d{2}$/
            },
            'vote_count.gte' => {
                type     => SCALAR,
                optional => 1,
                regex    => qr/^\d+$/
            },
            'vote_average.gte' => {
                type      => SCALAR,
                optional  => 1,
                regex     => qr/^\d{1,2}\.\d{1,}$/,
                callbacks => {
                    average => sub { $_[0] <= 10 },
                },
            },
            with_genres => {
                type     => SCALAR,
                optional => 1,
            },
            with_companies => {
                type     => SCALAR,
                optional => 1,
            },
        },
    );

  return $self->_search(
        {
            method => 'discover/movie',
            params => {
                language => $self->session->lang
                ? $self->session->lang
                : undef,
                include_adult => $self->include_adult,
                %options,
            },
        }
    );

} ## end sub discover

#######################
# FIND
#######################
sub find {
    my ( $self, @args ) = @_;
    my %options = validate_with(
        params => [@args],
        spec   => {
            id => {
                type => SCALAR,
            },
            source => {
                type => SCALAR,
            },
        },
    );

  return $self->session->talk(
        {
            method => 'find/' . $options{id},
            params => {
                external_source => $options{source},
                language        => $self->session->lang
                ? $self->session->lang
                : undef,
            }
        }
    );
} ## end sub find

#######################
# PRIVATE METHODS
#######################

## ====================
## Search
## ====================
sub _search {
    my $self = shift;
    my $args = shift;
    $args->{max_pages} = $self->max_pages();
  return $self->session->paginate_results($args);
} ## end sub _search

#######################
1;
