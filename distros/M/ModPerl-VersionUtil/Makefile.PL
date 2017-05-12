use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'ModPerl::VersionUtil',
    VERSION_FROM      => 'lib/ModPerl/VersionUtil.pm',
    PREREQ_PM         => {
        Class::Data::Inheritable => 0.02,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/ModPerl/VersionUtil.pm',
       AUTHOR         => 'naoya <naoya@bloghackers.net>') : ()),
);
