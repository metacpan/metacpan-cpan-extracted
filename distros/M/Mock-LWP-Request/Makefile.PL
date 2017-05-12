use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mock::LWP::Request',
    VERSION_FROM      => 'lib/Mock/LWP/Request.pm', # finds $VERSION
    PREREQ_PM         => {
        'Moo'               => 0,
        'HTTP::Status'      => 0,
        'HTTP::Response'    => 0,
        'LWP::UserAgent'    => 0,
        'Test::Exception'   => 0
        },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Mock/LWP/Request.pm', # retrieve abstract from module
       AUTHOR         => 'Jason Clifford <jason@ukfsn.org>') : ()),
);
