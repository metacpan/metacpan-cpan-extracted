use 5.14.2;
use strict;
use warnings;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Prometheus::Pushgateway',
    LICENSE           => 'perl_5',
    AUTHOR            => 'Pavel Andryushin',
    VERSION_FROM      => 'lib/Net/Prometheus/Pushgateway.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'LWP::UserAgent'          => '6.26',
    },
    META_MERGE   => {
          requires  => { perl => '5.14.2' },
          resources => {
                license     => 'http://dev.perl.org/licenses/',
                repository  => 'https://github.com/vrag86/perl-net-prometheus-pushgateway',
                bugtracker  => 'https://github.com/vrag86/perl-net-prometheus-pushgateway/issues'
              },
        },
    AUTHOR            => 'vrag <vrag867@gmail.com>',
);

