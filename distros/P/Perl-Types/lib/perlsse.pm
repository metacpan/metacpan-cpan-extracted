# [[[ HEADER ]]]
package  # hide from PAUSE indexing
    perlsse; ## no critic qw(Capitalization ProhibitMultiplePackages ProhibitReusedNames)  # SYSTEM DEFAULT 3: allow multiple & lower case package names
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ INCLUDES ]]]
use Perl::Structure::SSENumberPair;
#use RPerl::Operation::Expression::Operator::SSEIntrinsics;  # NEED DELETE, RPERL REFACTOR

# [[[ EXPORTS ]]]
use Exporter qw(import);
our @EXPORT = qw(sse_recip_sqrt_32bit_on_64bit);

1;  # end of package
