package Mojo::ACME::Key;

use Mojo::Base -base;

use Mojo::File;

use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::Bignum; # get_key_parameters
use Digest::SHA 'sha256';
use MIME::Base64 'encode_base64url';

has 'generated';
has string => sub { shift->key->get_private_key_string };
has key => sub {
  my $self = shift;
  my $path = $self->path;
  my $rsa;
  if ($path && -e $path) {
    my $string = Mojo::File->new($path)->slurp;
    $rsa = Crypt::OpenSSL::RSA->new_private_key($string);
    $self->generated(0);
  } else {
    $rsa = Crypt::OpenSSL::RSA->generate_key(4096);
    $self->generated(1);
  }
  return $rsa;
};
has 'path';
has pub => sub { Crypt::OpenSSL::RSA->new_public_key(shift->key->get_public_key_string) };

has jwk => sub {
  my ($n, $e) = shift->pub->get_key_parameters;
  return {
    kty => 'RSA',
    e => encode_base64url($e->to_bin),
    n => encode_base64url($n->to_bin),
  };
};

has thumbprint => sub {
  my $jwk = shift->jwk;
  # manually format json for sorted keys
  my $fmt = '{"e":"%s","kty":"%s","n":"%s"}';
  my $json = sprintf $fmt, @{$jwk}{qw/e kty n/};
  return encode_base64url( sha256($json) );
};

# TODO remove this once https://rt.cpan.org/Ticket/Display.html?id=111829&results=dcfe848f59fceab0efed819d62b70447
# is resolved and dependency on PKCS10 is bumped
sub key_clone { Crypt::OpenSSL::RSA->new_private_key(shift->string) }

sub sign {
  my ($self, $content) = @_;
  my $key = $self->key;
  $key->use_sha256_hash;
  return $key->sign($content);
}

1;

