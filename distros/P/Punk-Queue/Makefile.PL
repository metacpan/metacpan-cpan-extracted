use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;

# Punk::Queue consumes File::Raw::JSON's C ABI (frj_abi.h) for the job
# args/result/notes codec, so a job payload never crosses a Perl codec
# frame. The provider installs its header through ExtUtils::Depends, so
# there is one copy of the contract and it is the provider's - a consumer
# copy is a second source of truth that only drifts. The sibling-directory
# fallback is for building the whole Semantic tree from a checkout, before
# anything is installed.
#
# Hyperman (hm_abi.h) joins this list in phase 3, when the worker gains a
# loop. It is deliberately absent here: phase 1 has no worker.
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

# ---- no provider half (decision 2026-08-07) --------------------------------
# Punk::Queue publishes no C ABI. The once-planned pq_abi.h had exactly one
# named consumer - Punk::Plugin::Queue, which ships INSIDE this dist and
# reaches the internals directly - and an ABI with no out-of-dist consumer
# is an append-only-forever contract frozen before anyone exists to
# validate it. It returns if and only if the plugin ever moves into the
# Punk dist (or another out-of-dist consumer appears); the full provider
# design is kept in ../plan_punk_queue/phase-7-abi.md for that day, gotchas
# included (set_inc BEFORE save_config, delete the empty LIBS/LDFROM,
# re-add lib/ to the PM map).

my %WriteMakefileArgs = (
    NAME             => 'Punk::Queue',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Punk/Queue.pm',
    ABSTRACT_FROM    => 'lib/Punk/Queue.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010000',
    # File::Raw::JSON is needed HERE, at configure time - the block above
    # asks ExtUtils::Depends for its installed header before it can write
    # a Makefile. A client installs configure_requires before running
    # Makefile.PL and PREREQ_PM only after, so listing it below alone is
    # too late: a clean machine dies in that block with "Punk::Queue
    # needs ...", which is not a test failure but a configure that never
    # produced a Makefile.
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
                    # Punk::Plugin::Queue only; 0.04 is where the
                    # registrar grew install_kw, which is how the
                    # queue/task/cron keywords get into an app class
                    'Punk'        => '0.04',
                    # the admin UI's pages; required only when the
                    # plugin is registered with admin => {...}
                    'Template::Stencil' => '0.04',
                },
            },
        },
    },
    EXE_FILES => ['bin/punk-queue'],
    INC   => $INC,
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Punk-Queue-*' },
    # MakeMaker maps Queue.xs -> Queue.c and does not rescan the INCLUDE:
    # fragments or the C headers, so force a regenerate of Queue.c when an
    # xs/ fragment changes and a rebuild of the object when a header does.
    # Omitting this leaves a stale Queue.c and header edits silently do
    # nothing, which is a genuinely baffling half hour.
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
