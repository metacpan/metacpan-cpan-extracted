# [[[ HEADER ]]]
package  # hide from PAUSE indexing
    perlgsl; ## no critic qw(Capitalization ProhibitMultiplePackages ProhibitReusedNames)  # SYSTEM DEFAULT 3: allow multiple & lower case package names
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ INCLUDES ]]]
use Perl::Structure::GSLMatrix;
#use RPerl::Operation::Expression::Operator::GSLFunctions;  # NEED DELETE, RPERL REFACTOR
use Math::GSL::Matrix qw(:all);
# DEV NOTE: only import CBLAS global variables which may be needed by normal BLAS routines
use Math::GSL::CBLAS qw(
    $CblasRowMajor
    $CblasColMajor
    $CblasNoTrans
    $CblasTrans
    $CblasConjTrans
    $CblasUpper
    $CblasLower
    $CblasNonUnit
    $CblasUnit
    $CblasLeft
    $CblasRight
);
use Math::GSL::BLAS qw(:all);

# [[[ EXPORTS ]]]
use Exporter qw(import);
our @EXPORT = (
    @Perl::Structure::GSLMatrix::EXPORT,
#    @RPerl::Operation::Expression::Operator::GSLFunctions::EXPORT,  # NEED DELETE, RPERL REFACTOR
    @Math::GSL::Matrix::EXPORT,
    @Math::GSL::Matrix::EXPORT_OK,  # DEV NOTE: force export all allowed exports gsl_matrix_*(), so RPerl users only have to say 'use perlgsl;' w/out the 'qw(:all)'
    # DEV NOTE: only import CBLAS global variables which may be needed by normal BLAS routines
    qw(
        $CblasRowMajor
        $CblasColMajor
        $CblasNoTrans
        $CblasTrans
        $CblasConjTrans
        $CblasUpper
        $CblasLower
        $CblasNonUnit
        $CblasUnit
        $CblasLeft
        $CblasRight
    ),
    @Math::GSL::BLAS::EXPORT,
    @Math::GSL::BLAS::EXPORT_OK,  # DEV NOTE: force export all allowed exports gsl_blas_*(), so RPerl users only have to say 'use perlgsl;' w/out the 'qw(:all)'
);
our @EXPORT_OK = (
    @Perl::Structure::GSLMatrix::EXPORT_OK,
#    @RPerl::Operation::Expression::Operator::GSLFunctions::EXPORT_OK,  # NEED DELETE, RPERL REFACTOR
    @Math::GSL::Matrix::EXPORT_OK,
    @Math::GSL::CBLAS::EXPORT_OK,
    @Math::GSL::BLAS::EXPORT_OK,
);

# DEV NOTE: must hard-code type-checking here because RPerl::Exporter doesn't handle this type of thing just yet
*perltypes::gsl_matrix_CHECK = \&Perl::Structure::GSLMatrix::gsl_matrix_CHECK;
*perltypes::gsl_matrix_CHECKTRACE = \&Perl::Structure::GSLMatrix::gsl_matrix_CHECKTRACE;

1;  # end of package
