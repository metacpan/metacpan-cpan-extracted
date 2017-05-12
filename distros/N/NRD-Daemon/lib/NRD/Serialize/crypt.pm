package NRD::Serialize::crypt;

use Carp;

# overrides freeze and unfreeze methods, encrypting and
# unencrypting data first
use base 'NRD::Serialize::plain';

sub new {
  my ($class, $options) = @_;
  $options = {} if (not defined $options);
  my $self = {
    'encrypt_type' => undef,
    'encrypt_key' => undef,
    %$options
  };

  bless($self, $class);

  die 'No encrypt_type specified' if (not defined $self->{'encrypt_type'});
  die 'No encrypt_key specified' if (not defined $self->{'encrypt_key'});

  require Crypt::CBC or die "Can't load Crypt::CBC";
  $self->{'iv'} = Crypt::CBC->random_bytes(8)
    if (not defined $self->{'iv'});
  my $td = Crypt::CBC->new( -cipher => $self->{'encrypt_type'},
                            -key => $self->{'encrypt_key'},
                            -iv  => $self->{'iv'},
                            -header => 'none'
           ) or die "Can't load cipher '$self->{'encrypt_type'}'";

  $self->{'td'} = $td;
  return $self;
}

sub needs_helo { 1 }

sub helo {
  my ($self, $helo) = @_;
  # The IV is sent in the helo packet
  $self->{'td'}->iv($helo) if (defined $helo);
  return $self->{'td'}->iv;
}

sub freeze {
  my ($self, $result) = @_;
  my $string = $self->SUPER::freeze($result);
  my $td = $self->{'td'};
  return ($td->encrypt($string));
}

sub unfreeze {
  my ($self, $string) = @_;
  my $dec = $self->{'td'}->decrypt($string);
  $self->SUPER::unfreeze($dec);
}

1;
