package Search::Xapian::LogicError;

=head1 NAME

Search::Xapian::LogicError -  The base class for exceptions indicating errors in the program logic.

=head1 DESCRIPTION

  A subclass of LogicError will be thrown if Xapian detects a violation
  of a class invariant or a logical precondition or postcondition, etc.


=cut

use 5.006;
use strict;
use warnings;

require DynaLoader;

# For compatibility with XS Search::Xapian < 1.2.3 which still threw strings
# in some cases.
use overload '""' => sub { "Exception: ".$_[0]->get_msg };

use Search::Xapian::AssertionError;
use Search::Xapian::InvalidArgumentError;
use Search::Xapian::InvalidOperationError;
use Search::Xapian::UnimplementedError;

our @ISA = qw(DynaLoader Search::Xapian::Error);

1;
