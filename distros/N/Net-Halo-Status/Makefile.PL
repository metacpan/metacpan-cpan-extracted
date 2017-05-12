use 5.008005;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Net::Halo::Status',
    VERSION_FROM      => 'lib/Net/Halo/Status.pm',
    PREREQ_PM         => {IO::Socket::INET},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Net/Halo/Status.pm',
       AUTHOR         => 'Terje Bless <link@cpan.org>') : ()),
);

