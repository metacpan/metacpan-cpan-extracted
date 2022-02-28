package Search::Xapian::DatabaseError;

=head1 NAME

Search::Xapian::DatabaseError -  DatabaseError indicates some sort of database related error. 


=head1 DESCRIPTION


=cut

use 5.006;
use strict;
use warnings;

require DynaLoader;

# For compatibility with XS Search::Xapian < 1.2.3 which still threw strings
# in some cases.
use overload '""' => sub { "Exception: ".$_[0]->get_msg };

use Search::Xapian::DatabaseCorruptError;
use Search::Xapian::DatabaseCreateError;
use Search::Xapian::DatabaseLockError;
use Search::Xapian::DatabaseModifiedError;
use Search::Xapian::DatabaseOpeningError;

our @ISA = qw(DynaLoader Search::Xapian::RuntimeError);

1;
