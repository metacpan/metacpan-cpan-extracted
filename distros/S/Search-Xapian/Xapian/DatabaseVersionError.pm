package Search::Xapian::DatabaseVersionError;

=head1 NAME

Search::Xapian::DatabaseVersionError -  DatabaseVersionError indicates that a database is in an unsupported format.

=head1 DESCRIPTION

  From time to time, new versions of Xapian will require the database format
  to be changed, to allow new information to be stored or new optimisations
  to be performed.  Backwards compatibility will sometimes be maintained, so
  that new versions of Xapian can open old databases, but in some cases
  Xapian will be unable to open a database because it is in too old (or new)
  a format.  This can be resolved either be upgrading or downgrading the
  version of Xapian in use, or by rebuilding the database from scratch with
  the current version of Xapian.


=cut

use 5.006;
use strict;
use warnings;

require DynaLoader;

# For compatibility with XS Search::Xapian < 1.2.3 which still threw strings
# in some cases.
use overload '""' => sub { "Exception: ".$_[0]->get_msg };

our @ISA = qw(DynaLoader Search::Xapian::DatabaseOpeningError);

1;
