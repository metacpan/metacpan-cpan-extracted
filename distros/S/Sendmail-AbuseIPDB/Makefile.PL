use 5.010001;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Sendmail::AbuseIPDB',
    VERSION_FROM      => 'lib/Sendmail/AbuseIPDB.pm', # finds $VERSION
    PREREQ_PM         => {
                            'JSON' => 2.15,
                            'URI' => 1.4,
                         },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Sendmail/AbuseIPDB.pm', # retrieve abstract from module
       AUTHOR         => 'TTNDY <ttndy@cpan.org>') : ()),
);
