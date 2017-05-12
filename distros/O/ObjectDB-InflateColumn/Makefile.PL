use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'ObjectDB::InflateColumn',
    VERSION_FROM      => 'lib/ObjectDB/InflateColumn.pm',
    PREREQ_PM         => {
        'ObjectDB' => 0,
        'Module::Util' => 0,
        'Sub::Install' => 0
    }
);
