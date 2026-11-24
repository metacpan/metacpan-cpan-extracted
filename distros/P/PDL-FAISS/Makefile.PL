use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;

if (!-f '/usr/include/faiss/IndexFlat.h') {
    warn "libfaiss-dev (faiss/IndexFlat.h) is required to build PDL::FAISS.\n";
    exit 0;
}

my $pdl_inc = PDL::Core::Dev::PDL_INCLUDE();
$pdl_inc =~ s/^"|"$//g;

my $cpp_compiler = 'g++';
my $cpp_libs     = '-lstdc++';
my $cpp_flags    = '-std=c++17';
if (eval { require ExtUtils::CppGuess; 1 }) {
    my $guess = ExtUtils::CppGuess->new();
    my %opts  = $guess->makemaker_options();
    $cpp_compiler = $guess->compiler_command() || 'g++';
    $cpp_libs     = $guess->linker_flags()     || '-lstdc++';
    $cpp_flags    = ($opts{CCFLAGS} || '') . ' -std=c++17';
}

WriteMakefile(
    NAME               => 'PDL::FAISS',
    AUTHOR             => q{C.J. Collier <cjac@google.com>},
    VERSION_FROM       => 'lib/PDL/FAISS.pm',
    ABSTRACT_FROM      => 'lib/PDL/FAISS.pm',
    LICENSE            => 'apache_2_0',
    MIN_PERL_VERSION   => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::CppGuess'  => '0.26',
        'PDL'                 => '2.080',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {
        'PDL' => '2.080',
    },
    INC    => "-I. $pdl_inc",
    LIBS   => ["-lfaiss -lgomp -lblas -llapack $cpp_libs"],
    OBJECT => 'FAISS$(OBJ_EXT) faiss_bridge$(OBJ_EXT)',
    XS     => { 'FAISS.xs' => 'FAISS.c' },
    clean  => { FILES => 'PDL-FAISS-* *.o FAISS.bs FAISS.c' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/GoogleCloudPlatform/google-auth-library-perl.git',
                web  => 'https://github.com/GoogleCloudPlatform/google-auth-library-perl',
            },
            bugtracker => {
                web => 'https://github.com/GoogleCloudPlatform/google-auth-library-perl/issues',
            },
        },
    },
);

package MY;

sub postamble {
    return <<"END_MAKE";
CXX = $cpp_compiler
CXXFLAGS = $cpp_flags -O2 -fPIC

faiss_bridge\$(OBJ_EXT): faiss_bridge.cc faiss_bridge.h
\t\$(CXX) \$(CXXFLAGS) -I. -c faiss_bridge.cc -o faiss_bridge\$(OBJ_EXT)
END_MAKE
}
