use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'              => 'Sledge::Plugin::Notice',
    'VERSION_FROM'      => 'lib/Sledge/Plugin/Notice.pm',
    'PREREQ_PM'         => {
        Test::More => 0.32,
    },
);
