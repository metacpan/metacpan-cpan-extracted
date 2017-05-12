package TMDB::Person;

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
            method => 'person/' . $self->id(),
        }
    );
} ## end sub info

## ====================
## CREDITS
## ====================
sub credits {
    my $self = shift;
  return $self->session->talk(
        {
            method => 'person/' . $self->id() . '/credits',
        }
    );
} ## end sub credits

## ====================
## IMAGES
## ====================
sub images {
    my $self     = shift;
    my $response = $self->session->talk(
        {
            method => 'person/' . $self->id() . '/images',
        }
    );
  return $response->{profiles} || [];
} ## end sub images

## ====================
## VERSION
## ====================
sub version {
    my ($self) = @_;
    my $response = $self->session->talk(
        {
            method       => 'person/' . $self->id(),
            want_headers => 1,
        }
    ) or return;
    my $version = $response->{etag} || q();
    $version =~ s{"}{}gx;
  return $version;
} ## end sub version

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

# Alternative names
sub aka {
    my ($self) = @_;
    my $info = $self->info();
  return unless $info;
    my @aka = $info->{also_known_as} || [];
  return @aka if wantarray;
  return \@aka;
} ## end sub aka

# Bio
sub bio {
    my ($self) = @_;
    my $info = $self->info();
  return unless $info;
  return $info->{biography} || q();
} ## end sub bio

# Image
sub image {
    my ($self) = @_;
    my $info = $self->info();
  return unless $info;
  return $info->{profile_path} || q();
} ## end sub image

## ====================
## CREDIT HELPERS
## ====================

# Acted in
sub starred_in {
    my $self = shift;
    my $movies = $self->credits()->{cast} || [];
    my @names;
    foreach (@$movies) { push @names, $_->{title}; }
  return @names if wantarray;
  return \@names;
} ## end sub starred_in

# Crew member
sub directed           { return shift->_crew_names('Director'); }
sub produced           { return shift->_crew_names('Producer'); }
sub executive_produced { return shift->_crew_names('Executive Producer'); }
sub wrote { return shift->_crew_names('Author|Novel|Screenplay|Writer'); }

#######################
# PRIVATE METHODS
#######################

## ====================
## CREW NAMES
## ====================
sub _crew_names {
    my $self = shift;
    my $job  = shift;

    my @names;
    my $crew = $self->credits()->{crew} || [];
    foreach (@$crew) {
        push @names, $_->{title} if ( $_->{job} =~ m{$job}xi );
    }

  return @names if wantarray;
  return \@names;
} ## end sub _crew_names

#######################
1;
