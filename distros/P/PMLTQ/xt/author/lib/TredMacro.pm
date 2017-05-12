package TredMacro;

use strict;
use warnings;

use Treex::PML::Document;
use List::MoreUtils 'uniq';
use File::Basename 'basename';
use UNIVERSAL::DOES;

sub GetSecondaryFiles {
  my ($fsfile) = @_;
  # is probably the same as Treex::PML::Document->relatedDocuments()
  # a reference to a list of pairs (id, URL)
  my $requires = $fsfile->metaData('fs-require');
  my @secondary;
  if ($requires) {
    foreach my $req (@$requires) {
      my $id = $req->[0];
      my $req_fs
        = ref( $fsfile->appData('ref') )
          ? $fsfile->appData('ref')->{$id}
          : undef;
      if ( UNIVERSAL::DOES::does( $req_fs, 'Treex::PML::Document' ) ) {
        push( @secondary, $req_fs );
      }
    }
  }
  return uniq(@secondary);
}

sub ThisAddress {
  my ($node, $fsfile) = @_;
  my $type = $node->type;
  my ($id_attr) = $type && $type->find_members_by_role('#ID');

  return basename($fsfile->filename) . '#' . $node->{ $id_attr->get_name }
}

sub GetNodeIndex {
  my $node = shift;
  my $i = -1;
  while ($node) {
    $node = $node->previous();
    $i++;
  }
  return $i;
}

1;
