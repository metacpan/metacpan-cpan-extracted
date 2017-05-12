package NRD::Serialize::digest;

use strict;
use warnings;

use Carp;

# overrides freeze and unfreeze methods, encrypting and
# unencrypting data first
use base 'NRD::Serialize::plain';

sub new {
  my ($class, $options) = @_;
  $options = {} if (not defined $options);
  my $self = {
    'digest_type' => undef,
    'digest_key' => undef,
    %$options
  };

  bless($self, $class);

  die 'No digest_type specified' if (not defined $self->{'digest_type'});
  die 'No digest_key specified' if (not defined $self->{'digest_key'});

  require Digest or die "Can't load Digest";
  my $td = Digest->new( $self->{'digest_type'} );

  $self->{'digest'} = $td;
  return $self;
}

sub needs_helo { 0 }

sub helo {

}

sub freeze {
  my ($self, $result) = @_;

  if (exists $result->{'data'}){
    # hash our digest key together with the data in the result
    $self->{'digest'}->add( $self->{'digest_key'}, map { $result->{'data'}->{ $_ } } sort keys %{ $result->{'data'} } );
    # add the hash to the result
    $result->{'digest'} = $self->{'digest'}->digest;
  }

  return ($self->SUPER::freeze($result));
}

sub unfreeze {
  my ($self, $string) = @_;
  my $result = $self->SUPER::unfreeze($string);

  # remove the digest from the hash
  if (my $client_digest = delete $result->{'digest'}){

    # hash our digest key together with the data in the result
    $self->{'digest'}->add( $self->{'digest_key'}, map { $result->{'data'}->{ $_ } } sort keys %{ $result->{'data'} } );
    my $digest = $self->{'digest'}->digest;

    die 'Data recieved from client is not valid. Please check that digest_keys are the same'
      if ($client_digest ne $digest);
  }

  return $result;
}


1;
