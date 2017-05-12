use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Trustico',
    VERSION_FROM      => 'lib/Net/Trustico.pm', # finds $VERSION
    PREREQ_PM         => {
        'Time::Piece' => 0,
        'LWP::UserAgent' => 0,
        Carp => o,
        },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Trustico.pm', # retrieve abstract from module
       AUTHOR         => 'Jason Clifford <jason@ukfsn.org>') : ()),
);
