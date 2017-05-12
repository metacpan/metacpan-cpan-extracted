package TMDB::Genre;

#######################
# LOAD CORE MODULES
#######################
use strict;
use warnings FATAL => 'all';
use Carp qw(croak carp);

#######################
# LOAD CPAN MODULES
#######################
use Object::Tiny qw(id session);
use Params::Validate qw(validate_with :types);

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
            id => {
                type     => SCALAR,
                optional => 1,
            },
        },
    );

    my $self = $class->SUPER::new(%opts);
  return $self;
} ## end sub new

## ====================
## LIST
## ====================
sub list {
    my ($self) = @_;
    my $response = $self->session->talk(
        {
            method => 'genre/list',
            params => {
                language => $self->session->lang
                ? $self->session->lang
                : undef,
            },
        }
    );
  return unless $response;

    my $genres;
    $genres = $response->{genres} || [];
  return @$genres if wantarray;
  return $genres;
} ## end sub list

## ====================
## MOVIES
## ====================
sub movies {
    my ( $self, $max_pages ) = @_;
  return unless $self->id();
  return $self->session->paginate_results(
        {
            method    => 'genre/' . $self->id() . '/movies',
            max_pages => $max_pages,
            params    => {
                language => $self->session->lang
                ? $self->session->lang
                : undef,
            },
        }
    );
} ## end sub movies

#######################
1;
