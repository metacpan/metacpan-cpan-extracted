package SPVMImpl;

use strict;
use warnings;

package Digest::SHA;

*Digest::SHA::is_spvm = sub { 1 };

use warnings::register;

use SPVM 'Digest::SHA';

my @sha_funcs = qw(
  sha1    sha1_base64   sha1_hex
  sha224    sha224_base64   sha224_hex
  sha256    sha256_base64   sha256_hex
  sha384    sha384_base64   sha384_hex
  sha512    sha512_base64   sha512_hex
  sha512224 sha512224_base64  sha512224_hex
  sha512256 sha512256_base64  sha512256_hex
);

no strict 'refs';
for my $sha_func (@sha_funcs) {
  *{"Digest::SHA::$sha_func"} = sub (;@) {
    my (@args) = @_;
    
    my $data = join('', @args);

    if ($] >= 5.006) {
      utf8::downgrade($data);
    }
    
    my $output = SPVM::Digest::SHA->$sha_func($data);
    
    return $output->to_bin;
  };
}

my @hmac_sha_funcs = qw(
  hmac_sha1    hmac_sha1_base64   hmac_sha1_hex
  hmac_sha224    hmac_sha224_base64   hmac_sha224_hex
  hmac_sha256    hmac_sha256_base64   hmac_sha256_hex
  hmac_sha384    hmac_sha384_base64   hmac_sha384_hex
  hmac_sha512    hmac_sha512_base64   hmac_sha512_hex
  hmac_sha512224 hmac_sha512224_base64  hmac_sha512224_hex
  hmac_sha512256 hmac_sha512256_base64  hmac_sha512256_hex
);

no strict 'refs';
for my $hmac_sha_func (@hmac_sha_funcs) {
  *{"Digest::SHA::$hmac_sha_func"} = sub (;@) {
    my $key;
    if (@_ > 1) {
      $key = pop @_;
    }
    my (@args) = @_;
    
    my $data = join('', @args);

    if ($] >= 5.006) {
      utf8::downgrade($data);
    }
    
    my $output = SPVM::Digest::SHA->$hmac_sha_func($data, $key);
    
    return $output->to_bin;
  };
}

{
  my $orig = \&SPVM::Digest::SHA::add;
  *SPVM::Digest::SHA::add = sub {
    my ($self, @args) = @_;
    
    if ($^W || warnings::enabled()) {
      if (defined $args[0] && $args[0] eq 'Digest::SHA') {
        warn "Digest::SHA::md5 function probably called as class method";
      }
    }
    
    my $data = join('', @args);

    if ($] >= 5.006) {
      utf8::downgrade($data);
    }
    
    return $orig->($self, $data);
  };
}

{
  my $orig = \&SPVM::Digest::SHA::digest;
  *SPVM::Digest::SHA::digest = sub {
    my ($self) = @_;
    
    my $output = $orig->($self);
    
    return $output->to_bin;
  };
}

{
  my $orig = \&SPVM::Digest::SHA::hexdigest;
  *SPVM::Digest::SHA::hexdigest = sub {
    my ($self) = @_;
    
    my $output = $orig->($self);
    
    return $output->to_bin;
  };
}

{
  my $orig = \&SPVM::Digest::SHA::b64digest;
  *SPVM::Digest::SHA::b64digest = sub {
    my ($self) = @_;
    
    my $output = $orig->($self);
    
    return $output->to_bin;
  };
}

1;
