use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PerlGuard::Agent',
    VERSION_FROM      => 'lib/PerlGuard/Agent.pm', # finds $VERSION
    PREREQ_PM         => {
      'Moo' => 1,
      'JSON' => 0,
      'HTTP::Async' => 0,
      'Time::HiRes' => 0,
      'Data::UUID' => 0

      

    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PerlGuard/Agent.pm', # retrieve abstract from module
       AUTHOR         => 'Jonathan Taylor <jon@stackhaus.com>') : ()),
);
