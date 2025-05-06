## no critic qw(ProhibitUselessNoCritic PodSpelling ProhibitExcessMainComplexity)  # DEVELOPER DEFAULT 1a: allow unreachable & POD-commented code; SYSTEM SPECIAL 4: allow complex code outside subroutines, must be on line 1
package Perl::Structure::Array::SubTypes3D;
use strict;
use warnings;
use Perl::Types;
our $VERSION = 0.017_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(ProhibitUnreachableCode RequirePodSections RequirePodAtEnd)  # DEVELOPER DEFAULT 1b: allow unreachable & POD-commented code, must be after line 1
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(Capitalization ProhibitMultiplePackages ProhibitReusedNames)  # SYSTEM DEFAULT 3: allow multiple & lower case package names

# [[[ EXPORTS ]]]
# DEV NOTE, CORRELATION #rp051: hard-coded list of RPerl data types and data structures
use Exporter 'import';
our @EXPORT = qw();
our @EXPORT_OK = qw();

# [[[ PRE-DECLARED TYPES ]]]
package    # hide from PAUSE indexing
    boolean;
package    # hide from PAUSE indexing
    nonsigned_integer;
#package     # hide from PAUSE indexing
#    integer;
package    # hide from PAUSE indexing
    number;
package    # hide from PAUSE indexing
    character;
package    # hide from PAUSE indexing
    string;

# NEED ADD CODE HERE
# NEED ADD CODE HERE
# NEED ADD CODE HERE

# [[[ ARRAY REF ARRAY REF ARRAY REF ]]]
# [[[ ARRAY REF ARRAY REF ARRAY REF ]]]
# [[[ ARRAY REF ARRAY REF ARRAY REF ]]]

# (ref to array) of (refs to arrays) of (refs to arrays)
package arrayref::arrayref::arrayref;
use strict;
use warnings;
use parent -norequire, qw(arrayref);

# (ref to array) of (refs to arrays) of (refs to (arrays of integers))
package arrayref::arrayref::arrayref::integer;
use strict;
use warnings;
use parent -norequire, qw(arrayref::arrayref::arrayref);

# (ref to array) of (refs to arrays) of (refs to (arrays of numbers))
package arrayref::arrayref::arrayref::number;
use strict;
use warnings;
use parent -norequire, qw(arrayref::arrayref::arrayref);

# (ref to array) of (refs to arrays) of (refs to (arrays of strings))
package arrayref::arrayref::arrayref::string;
use strict;
use warnings;
use parent -norequire, qw(arrayref::arrayref::arrayref);

# (ref to array) of (refs to arrays) of (refs to (arrays of scalars))
package arrayref::arrayref::arrayref::scalartype;
use strict;
use warnings;
use parent -norequire, qw(arrayref::arrayref::arrayref);

1;  # end of package
