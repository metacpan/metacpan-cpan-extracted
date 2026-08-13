use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use Config;

my @PROVIDERS = (
    [ 'File::Raw::JSON'   => '../File-Raw-JSON/include'     ],  # frj_abi.h
    [ 'Open::API'         => '../Open-API/include'          ],  # oa_abi.h
    [ 'Template::Stencil' => '../Template-Stencil/include'  ],  # st_abi.h
    [ 'Hyperman'          => '../Hyperman/include/hyperman' ],  # hm_abi.h
    [ 'Markdown::Simple'  => '../Markdown-Simple/include'   ],  # mds_abi.h
    [ 'Search::Trigram'   => '../Search-Trigram/include'    ],  # sg_abi.h
    [ 'DBIx::Loop'        => '../DBIx-Loop/include'         ],  # dbil_abi.h
);
my $INC = '-Iinclude';
{
    my $dep;
    if (eval { $dep = ExtUtils::Depends->new('Punk',
                          map { $_->[0] } @PROVIDERS); 1 } && $dep) {
        my %v = $dep->get_makefile_vars;
        $INC .= ' ' . $v{INC} if $v{INC};
    }
    else {
        my @missing = grep { !-d $_->[1] } @PROVIDERS;
        die "Punk needs " . join(', ', map { $_->[0] } @missing)
          . " installed, or present as sibling directories.\n" if @missing;
        $INC .= join '', map { " -I$_->[1]" } @PROVIDERS;
    }
}

# getentropy(2) for CSRF token generation - macOS 10.12+, glibc 2.25+, the
# BSDs. It is declared in <sys/random.h> on macOS and <unistd.h> on glibc, so
# both are probed. Where it is missing punk_csrf.h falls back to a cached
# /dev/urandom descriptor, so this is a convenience, not a requirement.
my @DEFINE;
{
    my $dir = "punk_probe_$$";
    if (mkdir $dir) {
        for my $try ( [ 'sys/random.h', '-DPUNK_GETENTROPY_SYS_RANDOM' ],
                      [ 'unistd.h',     ''                             ] ) {
            my ($header, $extra) = @$try;
            my $src = "$dir/probe.c";
            open my $fh, '>', $src or next;
            print $fh "#include <$header>\n"
                . "int main(void) { char b[4]; return getentropy(b, 4); }\n";
            close $fh;
            my $cc = $Config{cc} || 'cc';
            if (system("$cc -c $src -o $dir/probe.o >/dev/null 2>&1") == 0) {
                push @DEFINE, '-DPUNK_HAVE_GETENTROPY';
                push @DEFINE, $extra if length $extra;
                unlink $src, "$dir/probe.o";
                last;
            }
            unlink $src, "$dir/probe.o";
        }
        rmdir $dir;
    }
    print "DEFINE:   @DEFINE\n" if @DEFINE;
}

my %WriteMakefileArgs = (
    NAME             => 'Punk',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Punk.pm',
    ABSTRACT_FROM    => 'lib/Punk.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010000',
    # Every provider above is needed HERE, at configure time: this file
    # asks ExtUtils::Depends for their installed headers before it can
    # write a Makefile. A client installs configure_requires before
    # running Makefile.PL and PREREQ_PM only after, so listing them below
    # alone is too late - a clean machine dies in the block above with
    # "Punk needs ... installed", which is not even a test failure, just
    # a configure that never produced a Makefile.
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'File::Raw::JSON'     => '0.06',   # provides frj_abi.h
        'Open::API'           => '0.09',   # provides oa_abi.h
        'Template::Stencil'   => '0.05',   # provides st_abi.h
        'Hyperman'            => '0.18',   # provides hm_abi.h (v3: rate limit)
        'Markdown::Simple'    => '0.21',   # provides mds_abi.h
        'Search::Trigram'     => '0.03',   # provides sg_abi.h
        'DBIx::Loop'          => '0.03',   # provides dbil_abi.h
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Open::API'            => '0.09',   # spec-first routing + validation; oa_abi.h
        'Template::Stencil'    => '0.05',   # Punk::View::Stencil; st_abi.h
        'File::Raw::JSON'      => '0.06',   # body decode / auto-JSON encode
        'Fetch'                => '0.12',   # $c->ua, on the worker's own loop
        'JSON::Schema::Fast'   => '0.05',   # schema field validation
        'YAML::XS'             => '0',      # Punk::Config; every scaffolded
                                            # app carries a config/punk.yml
        'Hyperman'             => '0.18',   # the native server; hm_abi.h's
                                            # detach ABI is what websocket
                                            # routes attach through, and v3
                                            # is the rate-limit / denylist arena
        'Markdown::Simple'     => '0.21',   # the markdown mount; mds_abi.h,
                                            # whose heading anchors and TOC
                                            # the docs shell is built on
        'Search::Trigram'      => '0.03',   # markdown search; sg_abi.h
        'DBIx::Loop'           => '0.03',   # Punk::Model::DBIx::Loop, the
                                            # async model backend; dbil_abi.h
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs => {
            runtime => {
                recommends => {
                    'Future'          => '0',     # non-blocking handlers
                    'DBI'             => '0',     # Punk::Model::DBI backend
                },
            },
        },
    },
    EXE_FILES => ['bin/punk'],   # the `punk new` scaffolder
    INC    => $INC,
    DEFINE => join(' ', @DEFINE),
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Punk-*' },
    # MakeMaker maps Punk.xs -> Punk.c and does not rescan the INCLUDE:
    # fragments or the C headers, so force a regenerate of Punk.c when an
    # xs/ fragment changes and a rebuild of the object when a header does.
    depend => {
        'Punk.c'         => join(' ', glob('xs/*.xs')),
        'Punk$(OBJ_EXT)' => join(' ', glob('include/punk/*.h'),
                                      glob('xs/*.xs')),
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
