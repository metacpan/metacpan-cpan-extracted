use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Nginx::ParseLog',
    VERSION_FROM      => 'lib/Nginx/ParseLog.pm', # finds $VERSION
    PREREQ_PM         => {
        "Regexp::IPv6" => "0.03",
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Nginx/ParseLog.pm', # retrieve abstract from module
       AUTHOR         => 'nrg <nrg@cpan.org>') : ()),
);
