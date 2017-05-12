use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SMS::Send::Clickatell',
    AUTHOR              => 'Brian McCauley <nobull@cpan.org>',
    VERSION_FROM        => 'lib/SMS/Send/Clickatell.pm',
    ABSTRACT_FROM       => 'lib/SMS/Send/Clickatell.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Test::MockObject' => 0,
	'SMS::Send' => 0,
	'HTTP::Request::Common' => 0,
	'LWP::UserAgent' => 0,
	'URI' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SMS-Send-Clickatell-*' },
);
