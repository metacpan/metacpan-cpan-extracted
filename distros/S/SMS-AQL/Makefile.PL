use 5.005000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SMS::AQL',
    VERSION_FROM      => 'lib/SMS/AQL.pm', # finds $VERSION
    PREREQ_PM         => { LWP::UserAgent => 0, HTTP::Request => 0 },
    MIN_PERL_VERSION  => 5.005,
    ($] > 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SMS/AQL.pm',
       AUTHOR         => 'David Precious <davidp@preshweb.co.uk>') : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),

    META_MERGE => {
        resources => {
            repository => 'https://github.com/bigpresh/SMS-AQL',
            bugtracker => 'https://github.com/bigpresh/SMS-AQL/issues',
            homepage   => 'https://github.com/bigpresh/SMS-AQL/',
        },
    },
);
