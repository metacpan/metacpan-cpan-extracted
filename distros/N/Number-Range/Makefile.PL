use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Number::Range',
    VERSION_FROM      => 'lib/Number/Range.pm', 
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Number/Range.pm',
       AUTHOR         => 'Larry Shatzer, Jr. <larrysh@cpan.org>') : ()),
);
