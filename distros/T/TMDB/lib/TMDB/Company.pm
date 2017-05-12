package TMDB::Company;

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
                type => SCALAR,
            },
        },
    );

    my $self = $class->SUPER::new(%opts);
  return $self;
} ## end sub new

## ====================
## INFO
## ====================
sub info {
    my $self = shift;
  return $self->session->talk(
        {
            method => 'company/' . $self->id(),
        }
    );
} ## end sub info

## ====================
## VERSION
## ====================
sub version {
    my ($self) = @_;
    my $response = $self->session->talk(
        {
            method       => 'company/' . $self->id(),
            want_headers => 1,
        }
    ) or return;
    my $version = $response->{etag} || q();
    $version =~ s{"}{}gx;
  return $version;
} ## end sub version

## ====================
## MOVIES
## ====================
sub movies {
    my ( $self, $max_pages ) = @_;
  return $self->session->paginate_results(
        {
            method    => 'company/' . $self->id() . '/movies',
            max_pages => $max_pages,
        }
    );
} ## end sub movies

## ====================
## INFO HELPERS
## ====================

# Name
sub name {
    my ($self) = @_;
    my $info = $self->info();
  return unless $info;
  return $info->{name} || q();
} ## end sub name

# Logo
sub logo {
    my ($self) = @_;
    my $info = $self->info();
  return unless $info;
  return $info->{logo_path} || q();
} ## end sub logo

# Image
sub image { return shift->logo(); }

#######################
1;
