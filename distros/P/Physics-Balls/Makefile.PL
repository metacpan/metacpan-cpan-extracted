use 5.010;
use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();
use File::Spec ();
use File::Temp ();

my $pkg = ExtUtils::Depends->new('Physics::Balls');
$pkg->install('include/pb_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');

my %dep = $pkg->get_makefile_vars;
delete @dep{qw(LIBS LDFROM INC)};
File::Find::find(sub {
    return unless -f && /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

my $contract = '';
{
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $src = File::Spec->catfile($dir, 'probe.c');
    my $obj = File::Spec->catfile($dir, 'probe.o');
    open my $fh, '>', $src or die "$src: $!";
    print {$fh} "int pb_probe(double a, double b, double c) { return a * b + c > 0; }\n";
    close $fh;
    my $null = File::Spec->devnull;
    if ($Config{cc} =~ /\bcl(?:\.exe)?\z/i) {
        $contract = ' /fp:strict';
    } elsif (system("$Config{cc} -ffp-contract=off -c -o $obj $src >$null 2>&1") == 0) {
        $contract = ' -ffp-contract=off';
    }
}

my $fpmath = '';
if ($Config{cc} !~ /\bcl(?:\.exe)?\z/i) {
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $src = File::Spec->catfile($dir, 'eval.c');
    my $obj = File::Spec->catfile($dir, 'eval.o');
    my $exe = File::Spec->catfile($dir, "eval$Config{_exe}");
    open my $fh, '>', $src or die "$src: $!";
    print {$fh} <<'C';
#include <float.h>
#if defined(FLT_EVAL_METHOD) && FLT_EVAL_METHOD != 0
#error a double is evaluated wider than a double
#endif
int main(void) { volatile double a = 1.5, b = 2; return a * b == 3 ? 0 : 1; }
C
    close $fh;
    my $null = File::Spec->devnull;
    my $sse = ' -mfpmath=sse -msse2';
    if (system("$Config{cc} -c -o $obj $src >$null 2>&1") != 0
        && system("$Config{cc}$sse -o $exe $src >$null 2>&1") == 0
        && system("$exe >$null 2>&1") == 0) {
        $fpmath = $sse;
    }
}

my %WriteMakefileArgs = (
    NAME             => 'Physics::Balls',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Physics/Balls.pm',
    ABSTRACT_FROM    => 'lib/Physics/Balls.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
        'JSON::PP'   => '0',
        'Test2::Bundle::Numerical' => '0.03',
        'Test2::Suite'             => '0.000060',
        'Math::BigRat' => '0.2613',
    },
    PREREQ_PM => {
        'Object::Proto::Sugar' => '0.05',
    },
    XS     => { 'Balls.xs' => 'Balls.c' },
    C      => [ 'Balls.c', 'pb_engine.c' ],
    OBJECT => 'Balls$(OBJ_EXT) pb_engine$(OBJ_EXT)',
    INC    => '-I. -Iinclude',
    CCFLAGS => "$Config{ccflags}$contract$fpmath",
    depend => {
        'Balls$(OBJ_EXT)'     => 'include/pb_abi.h',
        'pb_engine$(OBJ_EXT)' => 'include/pb_abi.h',
    },
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Physics-Balls-* Install' },
    %dep,
);

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
