use strict;
use warnings;

use ExtUtils::MakeMaker;

my %opts = (
    'NAME'             => 'Net::Daemon',
    'ABSTRACT_FROM'    => 'lib/Net/Daemon.pm',
    'AUTHOR'           => 'Jochen Wiedmann <joe@ispsoft.de>',
    'VERSION_FROM'     => 'lib/Net/Daemon.pm',                  # finds $VERSION
    'LICENSE'          => 'perl_5',
    'MIN_PERL_VERSION' => '5.006',
    'PREREQ_PM'       => {
        'Sys::Syslog' => '0.29',
    },
    'TEST_REQUIRES' => {
        'Test::More' => '0',
    },
    'dist' => {
        'DIST_DEFAULT' => q[all tardist],
        'COMPRESS'     => q[gzip -9vf],
        'SUFFIX'       => q[.gz]
    },
    'realclean' => { 'FILES' => 't/config ndtest.prt ndtest.cnt log' },
    'META_MERGE' => {
        'meta-spec' => { version => 2 },
        'resources' => {
            license    => ['http://dev.perl.org/licenses/'],
            bugtracker => {
                web => 'https://github.com/cpan-authors/Net-Daemon/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/cpan-authors/Net-Daemon.git',
                web  => 'https://github.com/cpan-authors/Net-Daemon',
            },
        },
    },
);

WriteMakefile(%opts);
