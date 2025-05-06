## no critic qw(ProhibitUselessNoCritic PodSpelling ProhibitExcessMainComplexity)  # DEVELOPER DEFAULT 1a: allow unreachable & POD-commented code; SYSTEM SPECIAL 4: allow complex code outside subroutines, must be on line 1
package Perl::Structure::Hash::SubTypes3D;
use strict;
use warnings;
use Perl::Types;
our $VERSION = 0.002_000;

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

# [[[ HASH REF HASH REF HASH REF ]]]
# [[[ HASH REF HASH REF HASH REF ]]]
# [[[ HASH REF HASH REF HASH REF ]]]

# (ref to hash) of (refs to hashes) of (refs to hashes)
package hashref::hashref::hashref;
use strict;
use warnings;
use parent -norequire, qw(hashref);

# (ref to hash) of (refs to hashes) of (refs to (hashes of integers))
package hashref::hashref::hashref::integer;
use strict;
use warnings;
use parent -norequire, qw(hashref::hashref::hashref);

# (ref to hash) of (refs to hashes) of (refs to (hashes of numbers))
package hashref::hashref::hashref::number;
use strict;
use warnings;
use parent -norequire, qw(hashref::hashref::hashref);

# (ref to hash) of (refs to hashes) of (refs to (hashes of strings))
package hashref::hashref::hashref::string;
use strict;
use warnings;
use parent -norequire, qw(hashref::hashref::hashref);

# (ref to hash) of (refs to hashes) of (refs to (hashes of scalars))
package hashref::hashref::hashref::scalartype;
use strict;
use warnings;
use parent -norequire, qw(hashref::hashref::hashref);

# [[[ HASH REF HASH REF ARRAY REF ]]]
# [[[ HASH REF HASH REF ARRAY REF ]]]
# [[[ HASH REF HASH REF ARRAY REF ]]]

# (ref to hash) of (refs to hashes) of (refs to arrays)
package hashref::hashref::arrayref;
use strict;
use warnings;
use parent -norequire, qw(hashref);

# (ref to hash) of (refs to hashes) of (refs to (arrays of integers))
package hashref::hashref::arrayref::integer;
use strict;
use warnings;
use parent -norequire, qw(hashref::hashref::arrayref);

# (ref to hash) of (refs to hashes) of (refs to (arrays of numbers))
package hashref::hashref::arrayref::number;
use strict;
use warnings;
use parent -norequire, qw(hashref::hashref::arrayref);

# (ref to hash) of (refs to hashes) of (refs to (arrays of strings))
package hashref::hashref::arrayref::string;
use strict;
use warnings;
use parent -norequire, qw(hashref::hashref::arrayref);

# (ref to hash) of (refs to hashes) of (refs to (arrays of scalars))
package hashref::hashref::arrayref::scalartype;
use strict;
use warnings;
use parent -norequire, qw(hashref::hashref::arrayref);

# [[[ HASH REF ARRAY REF HASH REF ]]]
# [[[ HASH REF ARRAY REF HASH REF ]]]
# [[[ HASH REF ARRAY REF HASH REF ]]]

# (ref to hash) of (refs to arrays) of (refs to hashes)
package hashref::arrayref::hashref;
use strict;
use warnings;
use parent -norequire, qw(hashref);

# (ref to hash) of (refs to arrays) of (refs to (hashes of integers))
package hashref::arrayref::hashref::integer;
use strict;
use warnings;
use parent -norequire, qw(hashref::arrayref::hashref);

# (ref to hash) of (refs to arrays) of (refs to (hashes of numbers))
package hashref::arrayref::hashref::number;
use strict;
use warnings;
use parent -norequire, qw(hashref::arrayref::hashref);

# (ref to hash) of (refs to arrays) of (refs to (hashes of strings))
package hashref::arrayref::hashref::string;
use strict;
use warnings;
use parent -norequire, qw(hashref::arrayref::hashref);

# (ref to hash) of (refs to arrays) of (refs to (hashes of scalars))
package hashref::arrayref::hashref::scalartype;
use strict;
use warnings;
use parent -norequire, qw(hashref::arrayref::hashref);

# [[[ HASH REF ARRAY REF ARRAY REF ]]]
# [[[ HASH REF ARRAY REF ARRAY REF ]]]
# [[[ HASH REF ARRAY REF ARRAY REF ]]]

# (ref to hash) of (refs to arrays) of (refs to arrays)
package hashref::arrayref::arrayref;
use strict;
use warnings;
use parent -norequire, qw(hashref);

# (ref to hash) of (refs to arrays) of (refs to (arrays of integers))
package hashref::arrayref::arrayref::integer;
use strict;
use warnings;
use parent -norequire, qw(hashref::arrayref::arrayref);

# (ref to hash) of (refs to arrays) of (refs to (arrays of numbers))
package hashref::arrayref::arrayref::number;
use strict;
use warnings;
use parent -norequire, qw(hashref::arrayref::arrayref);

# (ref to hash) of (refs to arrays) of (refs to (arrays of strings))
package hashref::arrayref::arrayref::string;
use strict;
use warnings;
use parent -norequire, qw(hashref::arrayref::arrayref);

# (ref to hash) of (refs to arrays) of (refs to (arrays of scalars))
package hashref::arrayref::arrayref::scalartype;
use strict;
use warnings;
use parent -norequire, qw(hashref::arrayref::arrayref);

1;  # end of package

