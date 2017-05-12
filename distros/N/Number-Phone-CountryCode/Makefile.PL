use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Number::Phone::CountryCode',
    VERSION_FROM      => 'lib/Number/Phone/CountryCode.pm', # finds $VERSION
    PREREQ_PM         => {
        'Class::Accessor' => 0
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Number/Phone/CountryCode.pm', # retrieve abstract from module
       AUTHOR         => 'Michael Schout <mschout@gkg.net>') : ()),
);
