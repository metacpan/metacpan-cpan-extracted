use 5.008002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Parse::EventLog',
    VERSION_FROM      => 'lib/Parse/EventLog.pm', # finds $VERSION
    PREREQ_PM         => { Encode => 1.9 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'John Eaglesham') : ()),
);
