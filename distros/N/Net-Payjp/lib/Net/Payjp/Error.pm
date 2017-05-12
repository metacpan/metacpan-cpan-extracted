package Net::Payjp::Error;

use strict;
use warnings;

use base 'Net::Payjp';

sub _write{
  my $self = shift;
  die shift."\n";
}

sub _api_key{
  my $self = shift;
  return 'api_key is required'."\n";
}

sub _request{
  my $self = shift;
  my %p = @_;
  my $res_content = $p{res_content};

  return $res_content;  
}

1;
