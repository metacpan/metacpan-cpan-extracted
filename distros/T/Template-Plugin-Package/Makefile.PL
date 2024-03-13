package main;

use 5.10.1;

use strict;
use warnings;
use ExtUtils::MakeMaker 6.46;

my %parms = (
    NAME                => 'Template::Plugin::Package',
    VERSION_FROM        => 'Package.pm', # finds $VERSION
    LICENSE             => 'artistic_2',
    MIN_PERL_VERSION    => '5.10.1',

    PM => {
        'Package.pm'    => '$(INST_LIB)/Template/Plugin/Package.pm',
    },

    PREREQ_PM   => {
        Carp                  => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.46',
    },
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.46',
    },
    TEST_REQUIRES    => {
        'Test::More' => '0.95',
    },

    dist => {
        COMPRESS        => 'gzip -9',
        SUFFIX          => '.gz',
        DIST_DEFAULT    => 'all tardist',
    },

    META_MERGE => {
        resources => {
            homepage    => 'https://github.com/petdance/template-plugin-package',
            bugtracker  => 'https://github.com/petdance/template-plugin-package/issues',
            repository  => 'git@github.com:petdance/template-plugin-package.git',
            license     => 'https://opensource.org/licenses/artistic-license-2.0.php',
        }
    },
);

WriteMakefile( %parms );
