use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Role::Multiton',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/Role/Multiton.pm',
    ABSTRACT_FROM => 'lib/Role/Multiton.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'      => 0,    # testing
        'Moo'             => 0,    # testing
        'Test::Exception' => 0,    # testing
        'Role::Tiny'      => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Role-Multiton-*' },
);
