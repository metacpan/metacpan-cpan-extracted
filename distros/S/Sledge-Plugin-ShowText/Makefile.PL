use ExtUtils::MakeMaker;
WriteMakefile(
        'NAME'         => 'Sledge::Plugin::ShowText',
        'VERSION_FROM' => 'lib/Sledge/Plugin/ShowText.pm', # finds $VERSION
        'PREREQ_PM'    => {
                Test::More        => 0.32,
        },
);
