#!/usr/bin/env perl
use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::PkgConfig;

sub find_source_highlight {
    ExtUtils::PkgConfig->find('source-highlight >= 3.1');
}

my %source_highlight_pkg = eval {
    if ( defined $ENV{PKG_CONFIG_PATH} and $ENV{PKG_CONFIG_PATH} eq '' ) {
        if ( prompt( 'Ignore possibly installed backend library?', 'no' ) =~
            m/^y(?:es)?$/i )
        {
            die "Possibly installed backend library is ignored";
        }
    }

    find_source_highlight();
};
if ( my $exn = $@ ) {
    print qq{
The native backend library GNU Source Highlight was not found. You can
possibly install it using the package manager of your operating system
with a command like

  aptitude install source-highlight libsource-highlight-dev

or

  yum install source-highlight

Make sure that you pick a version above 3.1 since older versions don't
provide the public API used by this Perl extension. Also make sure to
install the development headers and libraries so that the native part
of this extension can be built.

GNU Source Highlight project home page is

  https://www.gnu.org/software/src-highlite/

};
    die $exn;
}

WriteMakefile(
    NAME             => 'Syntax::SourceHighlight',
    VERSION          => '2.1.3',
    MIN_PERL_VERSION => v5.10,
    ABSTRACT         => 'Perl Binding to GNU Source Highlight',
    LICENSE          => 'unrestricted',
    AUTHOR =>
      [ 'Thomas Chust <chust@web.de>', 'Matt Latusek <matlib@matlibhax.com>' ],
    CONFIGURE_REQUIRES => { 'ExtUtils::PkgConfig' => '1.12' },
    PREREQ_PM          => { 'DynaLoader'          => 0, },
    META_MERGE         => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://gitlab.com/Matlib/Syntax-SourceHighlight.git',
                web  => 'https://gitlab.com/Matlib/Syntax-SourceHighlight',
            },
            bugtracker => {
                mailto => 'matlib@cpan.org',
                web =>
                  'https://gitlab.com/Matlib/Syntax-SourceHighlight/-/issues',
            },
        },
    },

    dist => {
        DIST_CP => 'cp',
        PREOP   => 'perl insert-version.PL',
    },

    CCFLAGS => $source_highlight_pkg{cflags},
    LIBS    => [ $source_highlight_pkg{libs} ],
    H       => ['SourceHighlight.hh'],
    OBJECT  => ['SourceHighlight.o'],
);
