use strict;
use warnings;

return {
    NAME   => 'Pod::Markdown::Githubert',
    AUTHOR => q{Lukas Mai <l.mai@web.de>},

    MIN_PERL_VERSION   => '5.10.0',  # technically we don't, but our prereqs require 5.10
    CONFIGURE_REQUIRES => {},
    BUILD_REQUIRES => {},
    PREREQ_PM => {
        'Pod::Markdown' => '3.200',
        'warnings'      => 0,
        'strict'        => 0,
    },
    TEST_REQUIRES => {
        'Test2::V0'      => 0,
        'HTML::Entities' => 0,
    },
    DEVELOP_REQUIRES   => {
        'Test::Pod' => 1.22,
    },

    REPOSITORY => [ codeberg => 'mauke' ],
    BUGTRACKER => 'https://codeberg.org/mauke/Pod-Markdown-Githubert/issues',

    #HARNESS_OPTIONS => ['j4'],
};
