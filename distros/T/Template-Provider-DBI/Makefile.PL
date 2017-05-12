use ExtUtils::MakeMaker;

WriteMakefile(
     NAME          => 'Template::Provider::DBI',
     VERSION_FROM  => 'lib/Template/Provider/DBI.pm',
     PREREQ_PM     => { 'DBI'                   => 0,
                        'DateTime::Format::DBI' => 0,
                        'Template'              => 2.15,
#                        'DBD::SQLite'           => 0,
                    },
);
