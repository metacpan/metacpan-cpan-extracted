use 5.14.2;
use strict;
use warnings;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::SyslogNg',
    LICENSE           => 'perl_5',
    AUTHOR            => 'Pavel Andryushin',
    VERSION_FROM      => 'lib/Net/SyslogNg.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'IO::Socket::INET'          => '1.31',
        'DateTime'                  => '1.18',
        'Sys::Hostname'             => '1.16',
    },
    META_MERGE   => {
          requires  => { perl => '5.14.2' },
          resources => {
                license     => 'http://dev.perl.org/licenses/',
                repository  => 'https://github.com/vrag86/perl-net-syslogng',
                bugtracker  => 'https://github.com/vrag86/perl-net-syslogng/issues'
              },
        },
    AUTHOR            => 'vrag <vrag867@gmail.com>',
);

