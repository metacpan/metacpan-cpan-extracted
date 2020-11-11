use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'Package::Role::ini',
    VERSION_FROM   => 'lib/Package/Role/ini.pm',
    PREREQ_PM      => {
                       'Path::Class'      => 0,
                       'Config::IniFiles' => 0,
                      },
    ABSTRACT_FROM  => 'lib/Package/Role/ini.pm',
    AUTHOR         => 'Michael R. Davis <mrdvt at cpan>',
);
