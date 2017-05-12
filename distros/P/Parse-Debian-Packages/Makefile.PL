use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME' => 'Parse::Debian::Packages',
    'VERSION_FROM' => 'lib/Parse/Debian/Packages.pm',
    'PREREQ_PM' => {
        'Test::More' => 0,
    });
