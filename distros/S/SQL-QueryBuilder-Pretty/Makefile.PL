use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SQL::QueryBuilder::Pretty',
    AUTHOR              => 'André Rivotti Casimiro <rivotti@cpan.com>',
    VERSION_FROM        => 'lib/SQL/QueryBuilder/Pretty.pm',
    ABSTRACT_FROM       => 'lib/SQL/QueryBuilder/Pretty.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'        => 0,
        'Module::Pluggable' => 3.9,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SQL-QueryBuilder-Pretty-*' },
);
