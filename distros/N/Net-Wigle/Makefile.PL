use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Wigle',
    VERSION_FROM      => 'lib/Net/Wigle.pm', # finds $VERSION
    PREREQ_PM         => {
      'JSON' => 0,
      'LWP::UserAgent' => 0,
      'Params::Validate' => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Wigle.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Allred <mikejallred@gmail.com>') : ()),
);
