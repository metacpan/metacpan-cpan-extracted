use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Quantum::Usrn',
    'VERSION_FROM'	=> 'Usrn.pm',
    'PREREQ_PM'		=> {'Crypt::Blowfish' => 2.06},
);
