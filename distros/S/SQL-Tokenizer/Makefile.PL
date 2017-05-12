use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SQL::Tokenizer',
    AUTHOR              => 'Igor Sutton Lopes <igor.sutton@gmail.com>',
    VERSION_FROM        => 'lib/SQL/Tokenizer.pm',
    ABSTRACT_FROM       => 'lib/SQL/Tokenizer.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => '0',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SQL-Tokenizer-*' },
);
