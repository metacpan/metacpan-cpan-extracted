use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Nagios::Status::HostStatus',
    AUTHOR              => 'Roy Crowder <rcrowder@cpan.org>',
    VERSION_FROM        => 'lib/Nagios/Status/HostStatus.pm',
    ABSTRACT_FROM       => 'lib/Nagios/Status/HostStatus.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Nagios::Status::Host' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Nagios-Status-HostStatus-*' },
);
