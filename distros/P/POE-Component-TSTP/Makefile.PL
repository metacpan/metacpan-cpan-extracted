use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME' => 'POE::Component::TSTP',
    'VERSION_FROM' => 'lib/POE/Component/TSTP.pm',
    'PREREQ_PM' => {
        'POE' => 0.20,
    },
    'ABSTRACT_FROM' => 'lib/POE/Component/TSTP.pm',
    'AUTHOR' => 'Matt Sergeant <matt@sergeant.org>',
);
