use 5.010000;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use Config;

# Platform-specific linker flags for symbol export
# Only add --export-dynamic on platforms where GNU ld is used.
# Solaris/SunOS use their own ld which doesn't support this flag.
my %platform_args;
if ($^O eq 'linux' || $^O eq 'freebsd' || $^O eq 'openbsd' || $^O eq 'netbsd' ||
    $^O eq 'dragonfly') {
    $platform_args{LDDLFLAGS} = $Config{lddlflags} . ' -Wl,--export-dynamic';
}
elsif ($^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'msys') {
    $platform_args{LDDLFLAGS} = ($Config{lddlflags} || '') . ' -Wl,--export-all-symbols';
}

# Set up ExtUtils::Depends so downstream XS modules can find our
# headers and link against us on Windows.
my $pkg = ExtUtils::Depends->new('Object::Proto');
$pkg->set_inc('-I.');
$pkg->install('include/object_types.h', 'include/object_compat.h', 'include/xop_compat.h');
$pkg->save_config('Install/Files.pm');

my %dep_vars = $pkg->get_makefile_vars;

# ExtUtils::Depends sets PM for header installation, but we must also
# include our own .pm file or it won't be installed to blib.
$dep_vars{PM}{'lib/Object/Proto.pm'} = '$(INST_LIB)/Object/Proto.pm';

my %WriteMakefileArgs = (
    NAME             => 'Object::Proto',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Object/Proto.pm',
    ABSTRACT_FROM    => 'lib/Object/Proto.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010000',
    OBJECT           => 'object$(OBJ_EXT)',
    C                => ['object.c'],
    XS               => {},
    FUNCLIST         => [qw(
        object_register_type_xs
        object_register_type_xs_ex
        object_get_registered_type
    )],
    DL_FUNCS         => { 'Object::Proto' => [] },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
       	'ExtUtils::Depends'   => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Object-Proto-*' },
    %platform_args,
    %dep_vars,
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
