use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Storable::CouchDB',
    VERSION_FROM => 'lib/Storable/CouchDB.pm',
    AUTHOR       => 'Michael R. Davis',
    ABSTRACT_FROM=> 'lib/Storable/CouchDB.pm',
    PREREQ_PM    => {
                     'Test::Simple'     => 0.44, #tests
                     'CouchDB::Client'  => 0,
                     'IO::Socket::INET' => 0,    #tests
                    },
    'META_MERGE' => {
                     'resources' => {
                       'repository' => {
                         'web' => 'https://github.com/mrdvt92/perl-Storable-CouchDB.git',
                         'url' => 'git@github.com:mrdvt92/perl-Storable-CouchDB.git',
                         'type' => 'git'
                       },
                       'homepage' => 'https://github.com/mrdvt92/perl-Storable-CouchDB',
                       'bugtracker' => {
                         'web' => 'https://github.com/mrdvt92/perl-Storable-CouchDB/issues'
                       }
                     },
                     'meta-spec' => {
                       'version' => 2
                     }
                    },
);
