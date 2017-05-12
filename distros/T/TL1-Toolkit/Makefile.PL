use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'TL1::Toolkit',
    VERSION_FROM      => 'lib/TL1/Toolkit.pm', # finds $VERSION
    PREREQ_PM         => {
      'threads::shared' => 0,
      'Thread::Queue::Any' => 0,
      'Net::Telnet' => 0,
      'Time::localtime' => 0,
      'Date::Manip' => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/TL1/Toolkit.pm', # retrieve abstract from module
       AUTHOR         => 'Ronald van der Pol <rvdp@sara.nl>, Andree Toonk <andree@sara.nl>') : ()),
);
