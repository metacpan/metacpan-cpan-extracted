use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'MySQL::Log::ParseFilter',
    VERSION_FROM      => 'lib/MySQL/Log/ParseFilter.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/MySQL/Log/ParseFilter.pm',
       AUTHOR         => 'Daniel Nichter (http://hackmysql.com/contact)') : ()),
);
