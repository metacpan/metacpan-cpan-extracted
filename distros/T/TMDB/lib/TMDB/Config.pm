package TMDB::Config;

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
use Object::Tiny qw(
  session
  config
  change_keys
  img_backdrop_sizes
  img_base_url
  img_secure_base_url
  img_poster_sizes
  img_profile_sizes
  img_logo_sizes
  img_default_size
);

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
            img_default_size => {
                type     => SCALAR,
                optional => 1,
                default  => 'original',
            },
        },
    );

    my $self = $class->SUPER::new(%opts);

    my $config = $self->session->talk( { method => 'configuration' } ) || {};
    $self->{config}             = $config;
    $self->{img_backdrop_sizes} = $config->{images}->{backdrop_sizes} || [];
    $self->{img_poster_sizes}   = $config->{images}->{poster_sizes} || [];
    $self->{img_profile_sizes}  = $config->{images}->{profile_sizes} || [];
    $self->{img_logo_sizes}     = $config->{images}->{logo_sizes} || [];
    $self->{img_base_url}       = $config->{images}->{base_url} || q();
    $self->{img_secure_base_url}
      = $config->{images}->{secure_base_url} || q();
    $self->{change_keys} = $config->{change_keys} || [];

  return $self;
} ## end sub new

#######################
1;
