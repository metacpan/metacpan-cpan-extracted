use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'String::Splitter',
    AUTHOR              => 'Pawel bbkr Pabian <cpan@bbkr.org>',
    VERSION_FROM        => 'lib/String/Splitter.pm',
    ABSTRACT_FROM       => 'lib/String/Splitter.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => '0',
        'Test::Exception' => '0',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'String-Splitter-*' },
);
