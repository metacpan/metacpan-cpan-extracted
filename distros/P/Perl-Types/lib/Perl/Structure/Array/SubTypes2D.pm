## no critic qw(ProhibitUselessNoCritic PodSpelling ProhibitExcessMainComplexity)  # DEVELOPER DEFAULT 1a: allow unreachable & POD-commented code; SYSTEM SPECIAL 4: allow complex code outside subroutines, must be on line 1
package Perl::Structure::Array::SubTypes2D;
use strict;
use warnings;
use Perl::Types;
our $VERSION = 0.017_100;

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

# [[[ ARRAY REF ARRAY REF (2-dimensional) ]]]
# [[[ ARRAY REF ARRAY REF (2-dimensional) ]]]
# [[[ ARRAY REF ARRAY REF (2-dimensional) ]]]

# (ref to array) of (refs to arrays)
package arrayref::arrayref;
use strict;
use warnings;
use parent -norequire, qw(arrayref);

# [[[ HOMOGENEOUS ARRAY REF ARRAY REF (2-dimensional) ]]] 
# [[[ HOMOGENEOUS ARRAY REF ARRAY REF (2-dimensional) ]]] 
# [[[ HOMOGENEOUS ARRAY REF ARRAY REF (2-dimensional) ]]] 

# method returning (ref to array) of (refs to (arrays of integers))
package arrayref::arrayref::integer::method;
use strict;
use warnings;
use parent -norequire, qw(method);

# (ref to array) of (refs to (arrays of integers))
package arrayref::arrayref::integer;
use strict;
use warnings;
use parent -norequire, qw(arrayref::arrayref);

use Perl::Config;  # for 'use English;' etc.




# START HERE: implement arrayref_arrayref_integer_CHECK() & arrayref_arrayref_integer_to_string() & arrayref_arrayref_integer_typetest() numbered variations as in Hash/SubTypes.pm, then arrayref_arrayref_TYPE, then arrayref_hashref_TYPE
# START HERE: implement arrayref_arrayref_integer_CHECK() & arrayref_arrayref_integer_to_string() & arrayref_arrayref_integer_typetest() numbered variations as in Hash/SubTypes.pm, then arrayref_arrayref_TYPE, then arrayref_hashref_TYPE
# START HERE: implement arrayref_arrayref_integer_CHECK() & arrayref_arrayref_integer_to_string() & arrayref_arrayref_integer_typetest() numbered variations as in Hash/SubTypes.pm, then arrayref_arrayref_TYPE, then arrayref_hashref_TYPE




# emulate C++ behavior by actually creating arrays (and presumably allocating memory) at initialization time
sub new {
    { my arrayref::arrayref::integer::method $RETURN_TYPE };
    ( my integer $row_count, my integer $column_count ) = @ARG;  # row-major form (RMF)
    my arrayref::arrayref::integer $retval = [];
    for my integer $j (0 .. ($row_count - 1)) {
        my arrayref::integer $retval_row = [];
        for my integer $i (0 .. ($column_count - 1)) {
            $retval_row->[$i] = undef;
        }
        $retval->[$j] = $retval_row;
    }
    return $retval;
}

# method returning (ref to array) of (refs to (arrays of numbers))
package arrayref::arrayref::number::method;
use strict;
use warnings;
use parent -norequire, qw(method);

# (ref to array) of (refs to (arrays of numbers))
package arrayref::arrayref::number;
use strict;
use warnings;
use parent -norequire, qw(arrayref::arrayref);

use Perl::Config;  # for 'use English;' etc.

# emulate C++ behavior by actually creating arrays (and presumably allocating memory) at initialization time
sub new {
    { my arrayref::arrayref::number::method $RETURN_TYPE };
    ( my integer $row_count, my integer $column_count ) = @ARG;  # row-major form (RMF)
    my arrayref::arrayref::number $retval = [];
    for my integer $j (0 .. ($row_count - 1)) {
        my arrayref::number $retval_row = [];
        for my integer $i (0 .. ($column_count - 1)) {
            $retval_row->[$i] = undef;
        }
        $retval->[$j] = $retval_row;
    }
    return $retval;
}

# method returning (ref to array) of (refs to (arrays of strings))
package  arrayref::arrayref::string::method;
use strict;
use warnings;
use parent -norequire, qw(method);

# (ref to array) of (refs to (arrays of strings))
package arrayref::arrayref::string;
use strict;
use warnings;
use parent -norequire, qw(arrayref::arrayref);

use Perl::Config;  # for 'use English;' etc.

# emulate C++ behavior by actually creating arrays (and presumably allocating memory) at initialization time
sub new {
    { my arrayref::arrayref::string::method $RETURN_TYPE };
    ( my integer $row_count, my integer $column_count ) = @ARG;  # row-major form (RMF)
    my arrayref::arrayref::string $retval = [];
    for my integer $j (0 .. ($row_count - 1)) {
        my arrayref::string $retval_row = [];
        for my integer $i (0 .. ($column_count - 1)) {
            $retval_row->[$i] = undef;
        }
        $retval->[$j] = $retval_row;
    }
    return $retval;
}

# method returning (ref to array) of (refs to (arrays of scalartypes))
package arrayref::arrayref::scalartype::method;
use strict;
use warnings;
use parent -norequire, qw(method);

# (ref to array) of (refs to (arrays of scalars))
package arrayref::arrayref::scalartype;
use strict;
use warnings;
use parent -norequire, qw(arrayref::arrayref);

use Perl::Config;  # for 'use English;' etc.

# emulate C++ behavior by actually creating arrays (and presumably allocating memory) at initialization time
sub new {
    { my arrayref::arrayref::scalartype::method $RETURN_TYPE };
    ( my integer $row_count, my integer $column_count ) = @ARG;  # row-major form (RMF)
    my arrayref::arrayref::scalartype $retval = [];
    for my integer $j (0 .. ($row_count - 1)) {
        my arrayref::scalartype $retval_row = [];
        for my integer $i (0 .. ($column_count - 1)) {
            $retval_row->[$i] = undef;
        }
        $retval->[$j] = $retval_row;
    }
    return $retval;
}

# [[[ ARRAY REF HASH REF ]]]
# [[[ ARRAY REF HASH REF ]]]
# [[[ ARRAY REF HASH REF ]]]

# (ref to array) of (refs to hashs)
package arrayref::hashref;
use strict;
use warnings;
use parent -norequire, qw(arrayref);


# NEED ANSWER: are object arrays really 2-D, or are they 1-D???

# [[[ ARRAY REF OBJECT ]]]
# [[[ ARRAY REF OBJECT ]]]
# [[[ ARRAY REF OBJECT ]]]

# (ref to array) of objects
package arrayref::object;
use strict;
use warnings;
use parent -norequire, qw(arrayref);

1;  # end of package
