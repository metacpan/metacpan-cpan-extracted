use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Test::CPAN::README',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/Test/CPAN/README.pm',
    ABSTRACT_FROM => 'lib/Test/CPAN/README.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'    => 0,
        'Test::Builder' => 0,
        'Module::Want'  => 0,
        'YAML::Syck'    => 0,
        'JSON::Syck'    => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Test-CPAN-README-*' },
);
