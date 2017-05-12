use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Schema::RackTables',
    LICENSE             => 'perl',
    AUTHOR              => 'Sebastien Aperghis-Tramoni (saper@cpan.org)',
    VERSION_FROM        => 'lib/Schema/RackTables.pm',
    ABSTRACT_FROM       => 'lib/Schema/RackTables.pm',
    META_MERGE          => {
        resources       => {
            repository  => 'https://github.com/maddingue/Schema-RackTables',
        },
    },
    PL_FILES            => {},
    PREREQ_PM => {
        # prereqs
        'Carp'                  => 0,
        'DBIx::Class::Schema'   => 0,
        'File::Basename'        => 0,
        'File::Spec::Functions' => 0,
        'JSON::XS'              => 0,
        'Moo'                   => 0,

        # build/test prereqs
        'Test::More'            => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Schema-RackTables-*' },
);
