use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Growl',
    AUTHOR              => 'Nathan McFarland <nmcfarl@cpan.org>',
    VERSION_FROM        => 'lib/Net/Growl.pm',
    ABSTRACT_FROM       => 'lib/Net/Growl.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp'    => 0,
        'IO::Socket'    => 0,
        'Exporter'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Growl-*' },
);
