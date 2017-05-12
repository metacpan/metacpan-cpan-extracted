use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Template::Plugin::YAML',
    'VERSION_FROM' => 'lib/Template/Plugin/YAML.pm',
    'PREREQ_PM'    => {
        'Test::More' => 0,
        'Template'   => 0,
        'YAML'       => 0,
    }
);
