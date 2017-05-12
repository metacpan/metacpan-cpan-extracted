use 5.000;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Storable::Ref',
    VERSION_FROM      => 'lib/Storable/Ref.pm',
    PREREQ_PM         => {Storable => 2},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (#ABSTRACT_FROM  => 'lib/Storable/Ref.pm', # retrieve abstract from module
       AUTHOR         => 'Vany Serezhkin <ivan@serezhkin.com>') : ()),
);
