use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;

my @PROVIDERS = (
    [ 'File::Raw::JSON' => '../File-Raw-JSON/include' ],   # frj_abi.h
);
my $INC = '-Iinclude';
{
    my $dep;
    if (eval { $dep = ExtUtils::Depends->new('Punk::Queue',
                          map { $_->[0] } @PROVIDERS); 1 } && $dep) {
        my %v = $dep->get_makefile_vars;
        $INC .= ' ' . $v{INC} if $v{INC};
    }
    else {
        my @missing = grep { !-d $_->[1] } @PROVIDERS;
        die "Punk::Queue needs " . join(', ', map { $_->[0] } @missing)
          . " installed, or present as sibling directories.\n" if @missing;
        $INC .= join '', map { " -I$_->[1]" } @PROVIDERS;
    }
}

my %WriteMakefileArgs = (
    NAME             => 'Punk::Queue',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Punk/Queue.pm',
    ABSTRACT_FROM    => 'lib/Punk/Queue.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010000',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'File::Raw::JSON'     => '0.05',   # provides frj_abi.h
    },
    TEST_REQUIRES => {
        'Test::More'   => '0',
        'DBI'          => '1.614',  # AutoInactiveDestroy
        'DBD::SQLite'  => '1.60',   # 3.8+ for partial indexes
    },
    PREREQ_PM => {
        'File::Raw::JSON' => '0.05',   # frj_abi.h; the job payload codec
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs => {
            runtime => {
                recommends => {
                    'DBI'         => '1.614',  # every shipped backend
                    'DBD::Pg'     => '3.5.0',  # Backend::Pg (phase 2)
                    'DBD::SQLite' => '1.60',   # Backend::SQLite
                    'Punk'        => '0.04',
                    'Template::Stencil' => '0.04',
                    'Time::Keeper::Recurrence' => '0.01',   # a cron tz as a time zone name
                },
            },
        },
    },
    EXE_FILES => ['bin/punk-queue'],
    INC   => $INC,
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Punk-Queue-*' },
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    depend => {
        'Queue.c'         => join(' ', glob('xs/*.xs')),
        'Queue$(OBJ_EXT)' => join(' ', glob('include/*.h'), glob('xs/*.xs')),
    },
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
