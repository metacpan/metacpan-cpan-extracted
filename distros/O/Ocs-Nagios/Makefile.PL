use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Ocs::Nagios',
    AUTHOR              => 'Julien SAFAR <jsasys@gmail.com>',
    VERSION_FROM        => 'lib/Ocs/Nagios.pm',
    ABSTRACT_FROM       => 'lib/Ocs/Nagios.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'XML::Simple' => 0,
        'SOAP::Lite' => 0,
        'XML::Entities' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Ocs-Nagios-*' },
);
