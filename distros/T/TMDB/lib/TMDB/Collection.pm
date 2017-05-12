package TMDB::Collection;

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
            method => 'collection/' . $self->id(),
            params => {
                language => $self->session->lang
                ? $self->session->lang
                : undef,
            },
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
            method       => 'collection/' . $self->id(),
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

# All titles
sub titles { return shift->_parse_parts('title'); }

# Title IDs
sub ids { return shift->_parse_parts('id'); }

#######################
# PRIVATE METHODS
#######################


sub _parse_parts {
    my $self  = shift;
    my $key   = shift;
    my $info  = $self->info();
    my $parts = $info ? $info->{parts} : [];
    my @stuff;
    foreach my $part (@$parts) {
      next unless $part->{$key};
        push @stuff, $part->{$key};
    } ## end foreach my $part (@$parts)
  return @stuff if wantarray;
  return \@stuff;
} ## end sub _parse_parts

#######################
1;
