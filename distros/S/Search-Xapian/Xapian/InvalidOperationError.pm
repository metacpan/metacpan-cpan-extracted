package Search::Xapian::InvalidOperationError;

=head1 NAME

Search::Xapian::InvalidOperationError -  InvalidOperationError indicates the API was used in an invalid way.

=head1 DESCRIPTION


=cut

use 5.006;
use strict;
use warnings;

require DynaLoader;

# For compatibility with XS Search::Xapian < 1.2.3 which still threw strings
# in some cases.
use overload '""' => sub { "Exception: ".$_[0]->get_msg };

our @ISA = qw(DynaLoader Search::Xapian::LogicError);

1;
