use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();
use Config;

my @PROVIDERS = (
    [ 'File::Raw::JSON'   => '../File-Raw-JSON/include'     ],
    [ 'File::Raw::XML'    => '../File-Raw-XML/include'      ],
    [ 'JSON::Schema::Fast'=> '../JSON-Schema-Fast/include'  ],
    [ 'Open::API'         => '../Open-API/include'          ],
    [ 'Template::Stencil' => '../Template-Stencil/include'  ],
    [ 'Hyperman'          => '../Hyperman/include/hyperman' ],
    [ 'Markdown::Simple'  => '../Markdown-Simple/include'   ],
    [ 'Search::Trigram'   => '../Search-Trigram/include'    ],
    [ 'DBIx::Loop'        => '../DBIx-Loop/include'         ],
    [ 'Apophis'           => '../Apophis/include'           ],
    [ 'Frozen'            => '../Frozen/include'            ],
);
my $INC = '-Iinclude';
my $pkg;
if (eval { $pkg = ExtUtils::Depends->new('Punk',
                      map { $_->[0] } @PROVIDERS); 1 } && $pkg) {
    # A sibling checkout, when there is one, comes FIRST - ahead of the
    # headers ExtUtils::Depends found in the installed dists.
    #
    # Otherwise a development tree compiles against whatever was last
    # installed while declaring a dependency on something newer, and the two
    # never meet: PREREQ_PM checks a .pm's $VERSION and the C is taken from
    # that dist's Install/ directory, so Punk can require Hyperman 0.45,
    # build against 0.44's hm_abi.h, and fail on a struct member that the
    # version it asked for does have. The failure names the member, not the
    # stale header, which is a long way from the cause.
    #
    # Nothing changes for an ordinary build: with no sibling directories
    # present this adds no paths at all.
    my @sib = grep { -d $_->[1] } @PROVIDERS;
    $INC .= join '', map { " -I$_->[1]" } @sib if @sib;
}
else {
    my @missing = grep { !-d $_->[1] } @PROVIDERS;
    die "Punk needs " . join(', ', map { $_->[0] } @missing)
      . " installed, or present as sibling directories.\n" if @missing;
    $INC .= join '', map { " -I$_->[1]" } @PROVIDERS;
    $pkg = ExtUtils::Depends->new('Punk');
}

$pkg->install('include/pk_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');
my %dep = $pkg->get_makefile_vars;
$INC .= ' ' . delete $dep{INC} if $dep{INC};
delete $dep{LIBS};
delete $dep{LDFROM};

File::Find::find(sub {
    return unless -f;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

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
            if (system("$cc $src -o $dir/probe >/dev/null 2>&1") == 0) {
                push @DEFINE, '-DPUNK_HAVE_GETENTROPY';
                push @DEFINE, $extra if length $extra;
                unlink $src, "$dir/probe";
                last;
            }
            unlink $src, "$dir/probe";
        }
        rmdir $dir;
    }
}

{
    my $dir = "punk_probe_mtime_$$";
    if (mkdir $dir) {
        for my $try ( [ 'st_mtim.tv_nsec',      '-DPUNK_STAT_MTIM'      ],
                      [ 'st_mtimespec.tv_nsec', '-DPUNK_STAT_MTIMESPEC' ],
                      [ 'st_mtimensec',         '-DPUNK_STAT_MTIMENSEC' ] ) {
            my ($field, $define) = @$try;
            my $src = "$dir/probe.c";
            open my $fh, '>', $src or next;
            print $fh "#include <sys/types.h>\n#include <sys/stat.h>\n"
                . "int main(void) { struct stat s; s.$field = 0;\n"
                . "return (int)s.$field; }\n";
            close $fh;
            my $cc = $Config{cc} || 'cc';
            if (system("$cc $src -o $dir/probe >/dev/null 2>&1") == 0) {
                push @DEFINE, $define;
                unlink $src, "$dir/probe";
                last;
            }
            unlink $src, "$dir/probe";
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
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'File::Raw::JSON'     => '0.06',
        'File::Raw::XML'      => '0.03',
        'JSON::Schema::Fast'  => '0.05',
        'Open::API'           => '0.09',
        'Apophis'             => '0.05',
        'Template::Stencil'   => '0.10',
        'Hyperman'            => '0.45',
        'Markdown::Simple'    => '0.21',
        'Search::Trigram'     => '0.03',
        'DBIx::Loop'          => '0.07',
        'Frozen'              => '0.06',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Open::API'            => '0.09',
        'Template::Stencil'    => '0.10',
        'File::Raw'            => '0.18',
        'File::Raw::JSON'      => '0.06',
        'File::Raw::XML'       => '0.03',
        'Fetch'                => '0.12',
        'JSON::Schema::Fast'   => '0.05',
        'YAML::XS'             => '0',
        'Hyperman'             => '0.45',
        'Markdown::Simple'     => '0.21',
        'Search::Trigram'      => '0.03',
        'Apophis'              => '0.05',
        'DBIx::Loop'           => '0.07',
        'Frozen'               => '0.06',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs => {
            runtime => {
                recommends => {
                    'Future'          => '0',
                    'Future::AsyncAwait'
                                      => '0.66',
                    'DBI'             => '0',
                    'Eshu'            => '0',
                },
            },
        },
    },
    EXE_FILES => ['bin/punk'],
    %dep,
    INC    => $INC,
    DEFINE => join(' ', @DEFINE),
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Punk-*' },
    depend => {
        'Punk.c'         => join(' ', glob('xs/*.xs')),
        'Punk$(OBJ_EXT)' => join(' ', glob('include/punk/*.h'),
                                      glob('xs/*.xs')),
    },
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
