use strict;

package MLTests;
use Mixin::Linewise::Readers
  -readers,
  -readers => { -suffix => '_sub', method => 'read_handle_sub' },
  -readers => { -suffix => '_mul', method => 'read_handle_mul' },
  -readers => { -suffix => '_utf8', method => 'read_handle_val' },
  -readers => { -suffix => '_raw', method => 'read_handle_val', binmode => ':raw' };

sub read_handle {
  my ($self, $fh) = @_;

  my %return;
  while (<$fh>) {
    chomp;
    my ($k, $v) = split /\s*=\s*/;
    ($return{$k} ||= 0) += $v;
  };

  return \%return;
}

sub read_handle_sub {
  my ($self, $fh) = @_;

  my %return;
  while (<$fh>) {
    chomp;
    my ($k, $v) = split /\s*=\s*/;
    ($return{$k} ||= 0) -= $v;
  };

  return \%return;
}

sub read_handle_mul {
  my ($self, $fh) = @_;

  my %return;
  while (<$fh>) {
    chomp;
    my ($k, $v) = split /\s*=\s*/;
    ($return{$k} ||= 1) *= $v;
  };

  return \%return;
}

sub read_handle_val {
  my ($self, $fh) = @_;

  my %return;
  while (<$fh>) {
    chomp;
    my ($k, $v) = split /\s*=\s*/;
    $return{$k} = $v;
  };

  return \%return;
}

1;
