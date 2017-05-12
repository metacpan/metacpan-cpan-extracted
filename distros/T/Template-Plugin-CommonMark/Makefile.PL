use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $eumm_v = $ExtUtils::MakeMaker::VERSION;

my %Makefile = (
    NAME             => 'Template::Plugin::CommonMark',
    AUTHOR           => q{A. Sinan Unur <nanis@cpan.org>},
    VERSION_FROM     => 'lib/Template/Plugin/CommonMark.pm',
    ABSTRACT_FROM    => 'lib/Template/Plugin/CommonMark.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    PREREQ_PM => {
        'CommonMark' => 0,
        'parent' => 0,
        'Template' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Template-Plugin-CommonMark-*' },
);

if ($eumm_v >= 6.5503) {
    $Makefile{BUILD_REQUIRES} = {
        'Test::More' => 0,
    };
}

if ($eumm_v >= 6.52) {
    $Makefile{CONFIGURE_REQUIRES} = {
        'ExtUtils::MakeMaker' => 0,
    };
}

if ($eumm_v >= 6.48) {
    $Makefile{MIN_PERL_VERSION} = 5.008;
}

if ($eumm_v >= 6.46) {
    $Makefile{META_MERGE} = {
        resources => {
            bugtracker => 'https://github.com/nanis/template-plugin-commonmark/issues',
            repository => 'https://github.com/nanis/template-plugin-commonmark',
        },
    };
}

WriteMakefile(%Makefile);

