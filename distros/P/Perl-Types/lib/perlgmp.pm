# [[[ HEADER ]]]
package  # hide from PAUSE indexing
    perlgmp; ## no critic qw(Capitalization ProhibitMultiplePackages ProhibitReusedNames)  # SYSTEM DEFAULT 3: allow multiple & lower case package names
use strict;
use warnings;
our $VERSION = 0.002_000;

# [[[ INCLUDES ]]]
#use perltypes;
use Perl::Type::GMPInteger;
#use RPerl::Operation::Expression::Operator::GMPFunctions;  # NEED UPDATE, RPERL REFACTOR

# [[[ EXPORTS ]]]
use Exporter qw(import);
our @EXPORT = qw(
    gmp_integer_CHECK gmp_integer_CHECKTRACE
    gmp_integer_to_boolean gmp_integer_to_nonsigned_integer gmp_integer_to_integer gmp_integer_to_number gmp_integer_to_character gmp_integer_to_string
    boolean_to_gmp_integer integer_to_gmp_integer nonsigned_integer_to_gmp_integer number_to_gmp_integer character_to_gmp_integer string_to_gmp_integer
    gmp_init gmp_init_set_nonsigned_integer gmp_init_set_signed_integer
    gmp_set gmp_set_nonsigned_integer gmp_set_signed_integer gmp_set_number gmp_set_string
    gmp_get_nonsigned_integer gmp_get_signed_integer gmp_get_number gmp_get_string
    gmp_add gmp_sub gmp_mul gmp_mul_nonsigned_integer gmp_mul_signed_integer gmp_sub_mul_nonsigned_integer gmp_add_mul_nonsigned_integer gmp_neg
    gmp_div_truncate_quotient
    gmp_cmp
);



# START HERE: figure out how to get gmp_integer_CHECK*() enabled as perltypes::gmp_integer_CHECK*() for automatic use by subroutine type-check code in Class.pm
# START HERE: figure out how to get gmp_integer_CHECK*() enabled as perltypes::gmp_integer_CHECK*() for automatic use by subroutine type-check code in Class.pm
# START HERE: figure out how to get gmp_integer_CHECK*() enabled as perltypes::gmp_integer_CHECK*() for automatic use by subroutine type-check code in Class.pm


=DISABLED_NEED_FIGURE_OUT
package
    perltypes;

#require perltypes;
use perlgmp;

# [[[ EXPORTS ]]]
use Exporter qw(import);
our @EXPORT = ( 
#@perltypes::EXPORT = (
    @perltypes::EXPORT,
    @perlgmp::EXPORT,
);
our @EXPORT_OK = ( 
#@perltypes::EXPORT_OK = (
    @perltypes::EXPORT_OK,
    @perlgmp::EXPORT_OK,
);

#use Data::Dumper;
#print 'in perltypes, have @perltypes::EXPORT = ', Dumper(\@perltypes::EXPORT), "\n";
#die 'TMP DEBUG';

=cut

1;  # end of package
