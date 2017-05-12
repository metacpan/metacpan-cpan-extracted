use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'String::CaseProfile',
    VERSION_FROM      => 'lib/String/CaseProfile.pm',
    PREREQ_PM         => {
                            'Test::Warn' => 0.05,
                         },
    LICENSE           => 'perl',
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/String/CaseProfile.pm', 
       AUTHOR         => 'Enrique Nell <perl_nell@telefonica.net>') : ()),
);
