use 5.005;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => "Redis::DistLock",
    VERSION_FROM   => "lib/Redis/DistLock.pm",
    PREREQ_PM      => {
        "Digest::SHA"  => 0,
        "MIME::Base64" => 0,
        "Redis"        => 0,
        "Time::HiRes"  => 0,
    },
    ABSTRACT_FROM  => "lib/Redis/DistLock.pm",
    AUTHOR         => 'Simon Bertrang <janus@cpan.org>, Ryan Bastic <ryan@bastic.net>',
    META_MERGE     => {
        resources      => {
            license        => 'http://dev.perl.org/licenses/',
            repository     => 'https://github.com/sbertrang/redis-distlock',
            bugtracker     => 'https://github.com/sbertrang/redis-distlock/issues',
        },
    },
    LICENSE        => 'perl',
);

# vim: ts=4 sw=4 et:
