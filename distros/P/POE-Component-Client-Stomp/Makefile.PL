use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'POE::Component::Client::Stomp',
    VERSION_FROM      => 'lib/POE/Component/Client/Stomp.pm', # finds $VERSION
    PREREQ_PM         => {POE => 0.38,
	                      Net::Stomp => 0,
                          POE::Filter::Stomp => 0.02, 
                          POE::Component::Client::Stomp::Utils => 0}, 
    LICENSE           => 'perl',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/POE/Component/Client/Stomp.pm', # retrieve abstract from module
       AUTHOR         => 'Kevin L. Esteb <kesteb@wsipc.org>') : ()),
);
