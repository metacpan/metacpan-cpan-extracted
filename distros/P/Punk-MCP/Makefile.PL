use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;

my @PROVIDERS = (
    [ 'Punk'               => '../Punk/include'             ],
    [ 'File::Raw::JSON'    => '../File-Raw-JSON/include'    ],
    [ 'JSON::Schema::Fast' => '../JSON-Schema-Fast/include' ],
);

my $INC = '-Iinclude';
{
    my $dep;
    if (eval { $dep = ExtUtils::Depends->new('Punk::Plugin::MCP',
                          map { $_->[0] } @PROVIDERS); 1 } && $dep) {
        # Only INC. get_makefile_vars also returns a PM map that REPLACES
        # MakeMaker's autodetected one, and lib/ then stops being installed.
        my %v = $dep->get_makefile_vars;
        $INC .= ' ' . $v{INC} if defined $v{INC} && length $v{INC};
    }
    else {
        require Cwd;
        my @missing = grep { !-d $_->[1] } @PROVIDERS;
        die "Punk::MCP needs " . join(', ', map { $_->[0] } @missing)
          . " installed, or present as sibling directories.\n" if @missing;
        $INC .= join '', map { ' -I' . (Cwd::abs_path($_->[1]) || $_->[1]) }
                              @PROVIDERS;
    }
}

# getentropy, probed by building an executable and not an object: an old
# compiler takes an undeclared function as a warning, so only the link says
# whether libc has it (FreeBSD before 12 does not).
my @DEFINE;
{
    require Config;
    my $dir = "pmcp_probe_$$";
    if (mkdir $dir) {
        for my $try ( [ 'sys/random.h', '-DPMCP_GETENTROPY_SYS_RANDOM' ],
                      [ 'unistd.h',     ''                             ] ) {
            my ($header, $extra) = @$try;
            my $src = "$dir/probe.c";
            open my $fh, '>', $src or next;
            print $fh "#include <$header>\n"
                . "int main(void) { char b[4]; return getentropy(b, 4); }\n";
            close $fh;
            my $cc = $Config::Config{cc} || 'cc';
            if (system("$cc $src -o $dir/probe >/dev/null 2>&1") == 0) {
                push @DEFINE, '-DPMCP_HAVE_GETENTROPY';
                push @DEFINE, $extra if length $extra;
                unlink $src, "$dir/probe";
                last;
            }
            unlink $src, "$dir/probe";
        }
        rmdir $dir;
    }
    print "DEFINE:   @DEFINE\n" if @DEFINE;
}

# NAME is the plugin, because the plugin is what calls XSLoader: the boot
# symbol and the auto/ path follow NAME. DISTNAME keeps the house Punk-<Name>.
my %WriteMakefileArgs = (
    NAME             => 'Punk::Plugin::MCP',
    DISTNAME         => 'Punk-MCP',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Punk/MCP.pm',
    ABSTRACT_FROM    => 'lib/Punk/MCP.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'Punk'                => '0.64',
        'File::Raw::JSON'     => '0.08',
        'JSON::Schema::Fast'  => '0.10',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Punk'               => '0.64',
        'File::Raw::JSON'    => '0.08',
        'JSON::Schema::Fast' => '0.10',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        no_index    => { directory => ['example', 't', 'xt', 'include'] },
        prereqs     => {
            runtime => {
                recommends => {
                    'Punk::OAuth2' => '0.08',
                    'Hyperman'     => '0.64',
                    'Punk::Plugin::OpenTelemetry' => '0.10',
                },
            },
        },
        resources   => {
            license => ['http://www.opensource.org/licenses/artistic-license-2.0'],
        },
    },
    INC    => $INC,
    DEFINE => join(' ', @DEFINE),
    macro  => { TARFLAGS => "--format=ustar -c -v -f" },
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean  => { FILES => 'Punk-MCP-*' },
    depend => {
        'MCP.c'         => join(' ', glob('xs/*.xs')),
        'MCP$(OBJ_EXT)' => join(' ', glob('include/pmcp/*.h')),
    },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}
delete $WriteMakefileArgs{META_MERGE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 };
delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
