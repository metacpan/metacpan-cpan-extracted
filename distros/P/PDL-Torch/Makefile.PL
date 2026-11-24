use 5.010;
use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;

sub _find_libtorch {
    if ($ENV{LIBTORCH} && (-f "$ENV{LIBTORCH}/include/torch/torch.h" || -f "$ENV{LIBTORCH}/include/torch/csrc/api/include/torch/torch.h")) {
        return ($ENV{LIBTORCH} . '/include', $ENV{LIBTORCH} . '/lib');
    }
    if (-f '/usr/include/torch/torch.h' || -f '/usr/include/torch/csrc/api/include/torch/torch.h') {
        my $libdir = -d '/usr/lib/x86_64-linux-gnu' ? '/usr/lib/x86_64-linux-gnu' : '/usr/lib';
        return ('/usr/include', $libdir);
    }
    my $py_prefix = `python3 -c 'import torch, os; print(os.path.dirname(torch.__file__))' 2>/dev/null` || '';
    chomp($py_prefix);
    if ($py_prefix && (-f "$py_prefix/include/torch/torch.h" || -f "$py_prefix/include/torch/csrc/api/include/torch/torch.h")) {
        return ("$py_prefix/include", "$py_prefix/lib");
    }
    return ();
}

my ($torch_inc, $torch_lib) = _find_libtorch();
if (!$torch_inc) {
    warn "libtorch (set LIBTORCH, install libtorch-dev, or install Python torch) is required to build PDL::Torch.\n";
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

my $inc_flags = "-I$torch_inc -I$torch_inc/torch/csrc/api/include";
my $lib_flags = "-L$torch_lib -Wl,-rpath,$torch_lib -ltorch -ltorch_cpu -lc10 $cpp_libs";

WriteMakefile(
    NAME               => 'PDL::Torch',
    AUTHOR             => q{C.J. Collier <cjac@google.com>},
    VERSION_FROM       => 'lib/PDL/Torch.pm',
    ABSTRACT_FROM      => 'lib/PDL/Torch.pm',
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
    INC    => "-I. $pdl_inc $inc_flags",
    LIBS   => [$lib_flags],
    OBJECT => 'Torch$(OBJ_EXT) torch_bridge$(OBJ_EXT)',
    XS     => { 'Torch.xs' => 'Torch.c' },
    clean  => { FILES => 'PDL-Torch-* *.o Torch.bs Torch.c' },
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
CXXFLAGS = $cpp_flags -O2 -fPIC $inc_flags

torch_bridge\$(OBJ_EXT): torch_bridge.cc torch_bridge.h
\t\$(CXX) \$(CXXFLAGS) -I. -c torch_bridge.cc -o torch_bridge\$(OBJ_EXT)
END_MAKE
}
