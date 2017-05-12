use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Telnet::Wrapper',
    AUTHOR              => 'Maarten Wallraf <perl@2nms.com>',
    VERSION_FROM        => 'lib/Net/Telnet/Wrapper.pm',
    ABSTRACT_FROM       => 'lib/Net/Telnet/Wrapper.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Net::Telnet' => 0,
        'Net::Telnet::Cisco' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Telnet-Wrapper-*' },
);
