#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                    => 'MogileFS-Network',
    VERSION_FROM            => 'lib/MogileFS/Network.pm',
    AUTHOR                  => 'Jonathan Steinert <hachi@cpan.org>',
    ABSTRACT                => 'MogileFS Server class for representing networks based on host IPs.',
    PREREQ_PM               => {
        'Net::Netmask' => 0,
        'Net::Patricia' => 0,
        'MogileFS::Server' => '2.50',
    },
);

