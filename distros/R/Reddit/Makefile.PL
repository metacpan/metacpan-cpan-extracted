use 5.012004;
use ExtUtils::MakeMaker;
use warnings;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Reddit',
    VERSION_FROM      => 'lib/Reddit.pm', # finds $VERSION

    PREREQ_PM         => {
        'LWP::UserAgent'  => 0,
        'JSON'            => 0,
        'HTTP::Cookies'   => 0,
        'Data::Dumper'    => 0,
        'common::sense'   => 0,

    }, # e.g., Module::Name => 1.1

    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Reddit.pm', # retrieve abstract from module
       AUTHOR         => 'jon <jon@>') : ()),
);
