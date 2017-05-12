package RWDE::DB::Deletable;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 508 $ =~ /(\d+)/;

=pod

=head2 delete_record()

Delete the present record from the DB

Requires the present record to be:
    - populated
    - have an index 

=cut

sub delete_record {
  my ($self, $params) = @_;

  my $dbh = $self->get_dbh();

  my $id_name = $self->{_id};
  my $count   = $dbh->do("DELETE FROM " . $self->{_table} . " WHERE " . $self->{_id} . "=" . $self->$id_name);

  return $count;
}

1;
