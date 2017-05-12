use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::DNS::Match',
    VERSION_FROM      => 'lib/Net/DNS/Match.pm', # finds $VERSION
    PREREQ_PM         => { }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/DNS/Match.pm', # retrieve abstract from module
       AUTHOR         => 'Wesley Young <wes@barely3am.com>') : ()),
    META_MERGE  => {
        resources   => {
            repository  => 'https://github.com/wesyoung/net-dns-match-perl',
        },
    }
);
