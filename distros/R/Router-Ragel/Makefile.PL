use 5.010;
use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;

# Router::Ragel generates Ragel source and builds it with Inline::C on the
# first compile(), so ragel, a C compiler and make must all be present at RUN
# time, not just at build time. Report NA rather than FAIL when any of them is
# missing: those hosts fail every test, which says nothing about the code. Set
# ROUTER_RAGEL_SKIP_TOOLCHAIN_CHECK=1 to build anyway (packagers who install
# the toolchain later in the pipeline).
sub have_tool {
    my $cmd = shift;
    return 0 unless defined $cmd && length $cmd;
    # Config entries can carry flags ('gcc -B/usr/bin'); the program is word one
    ($cmd) = $cmd =~ /\A\s*(\S+)/ or return 0;
    my @exts = $^O eq 'MSWin32' ? ('.exe', '.bat', '.cmd', '') : ('');
    if ($cmd =~ m{[/\\]}) { # already a path, do not search PATH for it
        for my $ext (@exts) { return 1 if -f "$cmd$ext" && -x _ }
        return 0;
    }
    for my $dir (grep length, split /\Q$Config{path_sep}\E/, $ENV{PATH} // '') {
        for my $ext (@exts) {
            return 1 if -f "$dir/$cmd$ext" && -x _;
        }
    }
    return 0;
}

# An unset Config entry is not evidence the tool is missing, so skip it
my @missing = grep { defined $_->[1] && length $_->[1] && !have_tool($_->[1]) } (
    ['the ragel state machine compiler', 'ragel'],
    ['a C compiler', $Config{cc}],
    ['make', $Config{make}],
);

unless ($ENV{ROUTER_RAGEL_SKIP_TOOLCHAIN_CHECK} || !@missing) {
    warn "Router::Ragel could not find: "
        . join(', ', map "$_->[0] ($_->[1])", @missing) . "\n";
    warn <<'MSG';
Routes are emitted as Ragel source and built through Inline::C when compile()
is first called, so ragel, a C compiler and make are all needed at run time,
not just at install time.

    Debian/Ubuntu: apt-get install ragel build-essential
    macOS:         brew install ragel (and the Xcode command line tools)
    source:        https://www.colm.net/open-source/ragel/

Install them and re-run Makefile.PL, or set ROUTER_RAGEL_SKIP_TOOLCHAIN_CHECK=1
to build without the check.
MSG
    exit 0;
}

my $version = MM->parse_version('lib/Router/Ragel.pm');

WriteMakefile(
    NAME => 'Router::Ragel',
    AUTHOR => 'vividsnow',
    LICENSE => 'perl_5',
    VERSION_FROM => 'lib/Router/Ragel.pm',
    ABSTRACT_FROM => 'lib/Router/Ragel.pod',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    PREREQ_PM => {
        'Carp' => 0,
        'Digest::MD5' => 0,
        'Inline' => 0,
        'Inline::C' => 0,
        'Inline::Filters::Ragel' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => '0.94', # subtest(); perl 5.10.1 only ships 0.92
        'Test::LeakTrace' => 0,
        'Devel::Size' => 0,
        'URI::Escape::XS' => 0,
        'Encode' => 0,
        'File::Temp' => 0,
        'Storable' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides => {
            'Router::Ragel' => {
                file => 'lib/Router/Ragel.pm',
                version => $version,
            },
        },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/vividsnow/Router-Ragel.git',
                web => 'https://github.com/vividsnow/Router-Ragel',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/Router-Ragel/issues',
            },
        },
        prereqs => {
            develop => {
                requires => {
                    'Benchmark' => 0,
                    'Router::XS' => 0,
                    'Router::R3' => 0,
                    'URI::Router' => 0,
                    'Plack::Request' => 0,
                    'Mojolicious' => 0,
                    'Test::Pod' => '1.41',
                    'Test::Pod::Coverage' => '1.08',
                    'Test::CheckManifest' => '0.9',
                    'Test::Spelling' => '0.12',
                    'Test::NoTabs' => 0,
                    'Test::EOL' => 0,
                    'Test::CPAN::Changes' => 0,
                    'Test::CPAN::Meta' => 0,
                    'Test::Kwalitee::Extra' => 0,
                    'Pod::Markdown' => 0, # generates README.md from the POD
                    'JSON::PP' => 0,
                },
            },
        },
    },
    test => { TESTS => 't/*.t' },
);

# README.md is generated from the POD rather than tracked beside it. Emit the
# rule only where it is needed and possible: a dist already carries the file, so
# an ordinary build must never shell out to an author tool, while a checkout or
# a git archive export has to build it or ship a dist with no README.
sub MY::postamble {
    return '' unless eval { require Pod::Markdown; 1 };
    return '' unless -d '.git' || !-f 'README.md';
    return <<'MAKE';
README.md : lib/Router/Ragel.pod
	pod2markdown lib/Router/Ragel.pod > README.md

pure_all :: README.md

create_distdir : README.md
MAKE
}
