use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Radius::SSG',
    VERSION_FROM      => 'SSG.pm', # finds $VERSION
    PREREQ_PM         => {Net::Radius::Packet => 1.44,
    			  Net::Radius::Dictionary => 1.43,
		  	  Net::UDP => 1.0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'SSG.pm', # retrieve abstract from module
       AUTHOR         => 'Chris Myers <c.myers@its.uq.edu.au>') : ()),
);
