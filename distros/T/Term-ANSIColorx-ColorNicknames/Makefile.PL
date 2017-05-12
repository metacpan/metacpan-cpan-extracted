
require 5.008;

use strict;
use ExtUtils::MakeMaker 6.46;

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

    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git@github.com:jettero/term--ansicolorx.git',
                web  => 'https://github.com/jettero/term--ansicolorx',
            }
        },
    },

    TEST_REQUIRES => {
        'IPC::Run'   => 0,
        'Path::Tiny' => 0,
    },

    LICENSE	=> 'GPL',

    ( $install_hi =~ m/n/i ? () : (EXE_FILES=>['bin/hi']) ),

    clean => { FILES => 'dist TEST' },
);
