use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Quota::OO',
    VERSION_FROM      => 'lib/Quota/OO.pm', 
    PREREQ_PM         => {
        'Quota'             => 0,
        'version'           => 0,
        'Class::Std'        => 0,
        'Class::Std::Utils' => 0,
    }, 
    ($] >= 5.005 ?    
      (ABSTRACT_FROM  => 'lib/Quota/OO.pm',
       AUTHOR         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>') : ()),
);
