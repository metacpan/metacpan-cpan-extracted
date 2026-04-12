use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

# BLAS detection
my ($blas_libs, $blas_inc, $have_blas) = ('', '', 0);

if ($^O eq 'darwin') {
    # macOS: use Accelerate framework
    $blas_libs = '-framework Accelerate';
    $have_blas = 1;
    print "BLAS: Using macOS Accelerate framework\n";
} elsif (-e '/usr/lib/libopenblas.so' || -e '/usr/lib/x86_64-linux-gnu/libopenblas.so') {
    $blas_libs = '-lopenblas';
    $have_blas = 1;
    print "BLAS: Using OpenBLAS\n";
} elsif (-e '/usr/lib/libblas.so' || -e '/usr/lib/x86_64-linux-gnu/libblas.so') {
    $blas_libs = '-lblas';
    $have_blas = 1;
    print "BLAS: Using system BLAS\n";
} else {
    print "BLAS: Not found, using tiled scalar fallback\n";
}

my $define = $have_blas ? '-DNMAT_HAVE_BLAS=1' : '-DNMAT_HAVE_BLAS=0';

my %WriteMakefileArgs = (
    NAME             => 'Numeric::Matrix',
    AUTHOR           => ['lnation <email@lnation.org>'],
    VERSION_FROM     => 'lib/Numeric/Matrix.pm',
    ABSTRACT_FROM    => 'lib/Numeric/Matrix.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
    },
    
    # XS compilation
    OBJECT           => 'nmat$(OBJ_EXT)',
    DEFINE           => $define,
    LIBS             => [$blas_libs],
    INC              => '-I. -Iinclude',
    
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Numeric-Matrix-*' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
