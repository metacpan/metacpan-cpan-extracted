=head1 NAME

PDLA::Lite - minimum PDLA module OO loader

=head1 DESCRIPTION

Loads the smallest possible set of modules for
PDLA to work, without importing an functions in
to the current namespace. This is the absolute
minimum set for PDLA.

Although no functions are defined (apart from
a few always exported by L<PDLA::Core|PDLA::Core>) you can still
use method syntax, viz:

  $x->wibble(42);

=head1 SYNOPSIS

 use PDLA::Lite; # Is equivalent to the following:

   use PDLA::Core '';
   use PDLA::Ops '';
   use PDLA::Primitive '';
   use PDLA::Ufunc '';
   use PDLA::Basic '';
   use PDLA::Slices '';
   use PDLA::Bad '';
   use PDLA::Version;
   use PDLA::Lvalue;

=cut

# Load the fundamental PDLA packages, no imports
# Because there are no imports, we do not need
# the usual 'eval in the user's namespace' routine.

use PDLA::Core '';
use PDLA::Ops '';
use PDLA::Primitive '';
use PDLA::Ufunc '';
use PDLA::Basic '';
use PDLA::Slices '';
use PDLA::Bad '';
use PDLA::Version ;  # Doesn't export anything - no need for ''
use PDLA::Lvalue;

package PDLA::Lite;
$VERSION = $PDLA::Version::VERSION;

;# Exit with OK status

1;
