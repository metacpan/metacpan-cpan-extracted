
require 5.010;

use strict;
use ExtUtils::MakeMaker 6.64;

my $install_hi = prompt("install the STDOUT pipe highlighter \".../hi\"?", "y");

WriteMakefile(
    NAME         => 'Term::ANSIColorx::ColorNicknames',
    VERSION_FROM => 'lib/Term/ANSIColorx/ColorNicknames.pm',

    PREREQ_PM    => {
        'Term::ANSIColor' => 4.0,
        'Term::Size'      => 0,
        'Text::Table'     => 0,
        'common::sense'   => 0,
    },

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.64,
    },

    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git@github.com:jettero/term--ansicolorx.git',
                web  => 'https://github.com/jettero/term--ansicolorx',
            }
        },
        x_authority    => "cpan:JETTERO",
        x_contributors => [
            q{Sergei Zhmylev <zhmylove@cpan.org>},
        ],
    },

    TEST_REQUIRES => {
        'IPC::Run'   => 0,
        'Path::Tiny' => 0,
    },

    LICENSE	=> 'GPL',

    ( $install_hi =~ m/n/i ? () : (EXE_FILES=>['bin/hi']) ),

    clean => { FILES => 'dist TEST' },

    depend => { pm_to_blib => 't/hi' },
);

sub MY::postamble {
    return <<'EOF';
t/hi: bin/hi
	grep -v '^#!' bin/hi > $@
EOF
}
