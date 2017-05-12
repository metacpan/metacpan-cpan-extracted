package RWDE::DB::DefaultDB;

use strict;
use warnings;

use RWDE::DB::DbRegistry;

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 508 $ =~ /(\d+)/;

## @method object get_db()
# (Enter get_db info here)
# @return
sub get_db {
  my ($self, $params) = @_;

  return 'default';
}

## @method object get_dbh()
# (Enter get_dbh info here)
# @return (Enter explanation for return value here)
sub get_dbh {
  my ($self, $params) = @_;

  return RWDE::DB::DbRegistry->get_dbh({ db => $self->get_db() });
}

1;

