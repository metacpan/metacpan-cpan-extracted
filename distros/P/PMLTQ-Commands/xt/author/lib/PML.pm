package PML;

use strict;
use warnings;

use Treex::PML::Document;

sub Schema {
  &Treex::PML::Document::schema;
}

sub GetNodeByID {
  my ( $id, $fsfile ) = @_;
  my $h = $fsfile->appData('id-hash');
  return $h && $id && $h->{$id};
}

1;
