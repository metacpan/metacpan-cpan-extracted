use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (NAME              => 'POE::Component::Proxy::TCP',
   VERSION_FROM      => 'lib/POE/Component/Proxy/TCP.pm', # finds $VERSION
   PREREQ_PM         => 
   {
    POE => 0.28,
    Tk => 8.0, # Only needed for example, so should this be required?
   }, 
   ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/POE/Component/Proxy/TCP.pm', # retrieve abstract from module
     AUTHOR         => 'Andrew V. Purshottam <andy@andypurshottam.com>') : ()),
  );
