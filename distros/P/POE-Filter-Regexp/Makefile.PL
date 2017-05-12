use 5.000;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'POE::Filter::Regexp',
    VERSION_FROM      => 'lib/POE/Filter/Regexp.pm',
    PREREQ_PM         => {POE => 0.1000},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (#ABSTRACT_FROM  => 'lib/POE/Filter/Regexp.pm', # retrieve abstract from module
       AUTHOR         => 'Vany Serezhkin <ivan@serezhkin.com>') : ()),
);
