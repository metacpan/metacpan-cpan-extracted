use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'QQ::exmail',
    VERSION_FROM      => 'lib/QQ/exmail.pm', # finds $VERSION
    DISTNAME            => 'QQ-exmail',
    LICENSE             => "perl",
    PREREQ_PM         => {
        "JSON"                  => 0,
        "LWP::UserAgent"        => 0,
        "LWP::Protocol::https"  => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
       ABSTRACT_FROM  => 'lib/QQ/exmail.pm', # retrieve abstract from module
       ABSTRACT       => 'QQ::exmail - api for QQ exmail',
       AUTHOR         => 'yourself <admz@mail.scuec.edu.cn>') : ()),
);
