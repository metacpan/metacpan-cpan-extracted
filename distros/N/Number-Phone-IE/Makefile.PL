use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Number::Phone::IE',
    VERSION_FROM      => 'lib/Number/Phone/IE.pm', # finds $VERSION
    PREREQ_PM         => { Number::Phone => 1.2 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Dermot McNally <dermotm@gmail.com>') : ()),
);
