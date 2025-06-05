# [[[ HEADER ]]]
package Perl::Structure::MongoDBBSON;
use strict;
use warnings;
use Perl::Config;  # don't use Perl::Types inside itself, in order to avoid circular includes
our $VERSION = 0.001_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Class);
use Perl::Class;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(Capitalization ProhibitMultiplePackages ProhibitReusedNames)  # SYSTEM DEFAULT 3: allow multiple & lower case package names

# [[[ SUB-TYPES ]]]
package bson_document;
1;    # end of class

package bson_document__optional;
1;    # end of class

package arrayref::bson;
1;    # end of class

package hashref::bson;
1;    # end of class



# [[[ SWITCH CONTEXT BACK TO PRIMARY PACKAGE ]]]
package Perl::Structure::MongoDBBSON;
use strict;
use warnings;

# [[[ EXPORTS ]]]
use Exporter 'import';
our @EXPORT = qw(
    bson_build
    bson_Dumper
);

# DEV NOTE: do nothing in Perl, this subroutine is only used in C++
sub bson_build {
    { my bson_document $RETURN_TYPE };
    ( my hashref $bson_document_raw ) = @ARG;
    return $bson_document_raw;
}

sub bson_Dumper {
    { my string $RETURN_TYPE };
    ( my bson_document $bson_document ) = @ARG;
    return Dumper($bson_document);
}

1;    # end of class
