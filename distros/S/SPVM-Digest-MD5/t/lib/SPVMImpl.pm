package SPVMImpl;

use strict;
use warnings;

use SPVM 'Digest::MD5';

package Digest::MD5;

use warnings::register;

*Digest::MD5::md5 = sub {
  my (@args) = @_;
  
  if ($^W || warnings::enabled()) {
    if (defined $args[0] && $args[0] eq 'Digest::MD5') {
      warn "Digest::MD5::md5 function probably called as class method";
    }
  }
  
  my $data = join('', @args);

  if ($] >= 5.006) {
    utf8::downgrade($data);
  }
  
  my $output = SPVM::Digest::MD5->md5($data);
  
  return $output->to_bin;
};

*Digest::MD5::md5_hex = sub {
  my (@args) = @_;
  
  if ($^W || warnings::enabled()) {
    if (defined $args[0] && $args[0] eq 'Digest::MD5') {
      warn "Digest::MD5::md5_hex function probably called as class method";
    }
  }
  
  my $data = join('', @args);
  
  if ($] >= 5.006) {
    utf8::downgrade($data);
  }
  
  my $output = SPVM::Digest::MD5->md5_hex($data);
  
  return $output->to_bin;
};

*Digest::MD5::md5_base64 = sub {
  my (@args) = @_;
  
  if ($^W || warnings::enabled()) {
    if (defined $args[0] && $args[0] eq 'Digest::MD5') {
      warn "Digest::MD5::md5_base64 function probably called as class method";
    }
  }
  
  my $data = join('', @args);
  
  if ($] >= 5.006) {
    utf8::downgrade($data);
  }
  
  my $output = SPVM::Digest::MD5->md5_base64($data);
  
  return $output->to_bin;
};

*Digest::MD5::is_spvm = sub { 1 };
