use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Template::Plugin::Nbsp',
    'VERSION_FROM' => 'lib/Template/Plugin/Nbsp.pm',
    'PREREQ_PM'    => {'Template' => 2.0,
                      },
);
