package Search::Xapian::DatabaseOpeningError;

=head1 NAME

Search::Xapian::DatabaseOpeningError -  DatabaseOpeningError indicates failure to open a database. 


=head1 DESCRIPTION


=cut

use 5.006;
use strict;
use warnings;

require DynaLoader;

# For compatibility with XS Search::Xapian < 1.2.3 which still threw strings
# in some cases.
use overload '""' => sub { "Exception: ".$_[0]->get_msg };

use Search::Xapian::DatabaseVersionError;

our @ISA = qw(DynaLoader Search::Xapian::DatabaseError);

1;
