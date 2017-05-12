use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'TRD::WebRelayMail',
    AUTHOR              => 'Takuya Ichikawa <ichi@cpan.org>',
    VERSION_FROM        => 'lib/TRD/WebRelayMail.pm',
    ABSTRACT_FROM       => 'lib/TRD/WebRelayMail.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
		'Carp'       => 0,
		'CGI'        => 0,
		'LWP'        => 0,
		'Test::Perl::Critic' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'TRD-WebRelayMail-*' },
);
