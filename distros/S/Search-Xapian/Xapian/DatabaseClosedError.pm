package Search::Xapian::DatabaseClosedError;

=head1 NAME

Search::Xapian::DatabaseClosedError -  Indicates an attempt to access a closed database.

=head1 DESCRIPTION


=cut

use 5.006;
use strict;
use warnings;

require DynaLoader;

# For compatibility with XS Search::Xapian < 1.2.3 which still threw strings
# in some cases.
use overload '""' => sub { "Exception: ".$_[0]->get_msg };

our @ISA = qw(DynaLoader Search::Xapian::DatabaseError);

1;
