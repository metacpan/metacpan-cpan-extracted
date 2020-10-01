use strict;
use warnings;

use ExtUtils::MakeMaker;

my %opts = (
    'NAME'          => 'Net::Daemon',
    'ABSTRACT_FROM' => 'lib/Net/Daemon.pm',
    'AUTHOR'        => 'Jochen Wiedmann <joe@ispsoft.de>',
    'VERSION_FROM'  => 'lib/Net/Daemon.pm',                  # finds $VERSION
    'PREREQ_PM'     => {
        'Sys::Syslog' => '0.29',
    },
    'dist' => {
        'DIST_DEFAULT' => q[all tardist],
        'COMPRESS'     => q[gzip -9vf],
        'SUFFIX'       => q[.gz]
    },
    'realclean' => { 'FILES' => 't/config ndtest.prt' },
    'META_MERGE' => {
        'resources' => {
            license    => 'http://dev.perl.org/licenses/',
            bugtracker => 'https://github.com/toddr/Net-Daemon/issues',
            repository => 'https://github.com/toddr/Net-Daemon',
        },
    },
);

WriteMakefile(%opts);
