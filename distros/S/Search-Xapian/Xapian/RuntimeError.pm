package Search::Xapian::RuntimeError;

=head1 NAME

Search::Xapian::RuntimeError -  The base class for exceptions indicating errors only detectable at runtime.

=head1 DESCRIPTION

  A subclass of RuntimeError will be thrown if Xapian detects an error
  which is exception derived from RuntimeError is thrown when an
  error is caused by problems with the data or environment rather
  than a programming mistake.


=cut

use 5.006;
use strict;
use warnings;

require DynaLoader;

# For compatibility with XS Search::Xapian < 1.2.3 which still threw strings
# in some cases.
use overload '""' => sub { "Exception: ".$_[0]->get_msg };

use Search::Xapian::DatabaseError;
use Search::Xapian::DocNotFoundError;
use Search::Xapian::FeatureUnavailableError;
use Search::Xapian::InternalError;
use Search::Xapian::NetworkError;
use Search::Xapian::QueryParserError;
use Search::Xapian::SerialisationError;
use Search::Xapian::RangeError;

our @ISA = qw(DynaLoader Search::Xapian::Error);

1;
