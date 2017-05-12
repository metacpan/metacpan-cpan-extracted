package Perl::APIReference::V5_016_002;
use strict;
use warnings;
use parent 'Perl::APIReference::V5_016_000';

sub new {
  my $class = shift;
  my $obj = $class->SUPER::new(@_);

  $obj->{perl_version} = '5.016002';
  bless $obj => $class;
  # Override the only change since 5.16.0
  $obj->{'index'}{'mg_get'} = {'text' => 'Do magic before a value is retrieved from the SV.  See C<sv_magic>.

	int	mg_get(SV* sv)','name' => 'mg_get'};
  return $obj;
}

1;
