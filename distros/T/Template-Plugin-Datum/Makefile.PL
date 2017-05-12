use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Template::Plugin::Datum',
    'VERSION_FROM' => 'lib/Template/Plugin/Datum.pm',
    'PREREQ_PM'    => {'Template' => 2.0,
                      },
);
