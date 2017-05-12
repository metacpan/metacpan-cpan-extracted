use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Term::VT102::Boundless',
    'VERSION_FROM' => 'lib/Term/VT102/Boundless.pm',
    'PREREQ_PM'    => {
        'Term::VT102'   => 0.91,
        'Test::More'    => '0.53',
        'Test::use::ok' => 0,
    },
    'INSTALLDIRS' => 'site',
    'PL_FILES'    => {}
);
