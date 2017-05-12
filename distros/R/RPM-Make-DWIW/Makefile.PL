use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'RPM::Make::DWIW',
    VERSION_FROM  => 'lib/RPM/Make/DWIW.pm',
    PREREQ_PM     => { }, 
   ($] >= 5.005 ?
        ('AUTHOR'               => 'Asher Blum <asher@wildsparx.com>',
        'ABSTRACT'              => 'Simple API to create RPMs', ) : ()),
);
