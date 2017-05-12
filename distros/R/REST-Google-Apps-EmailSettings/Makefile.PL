use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'REST::Google::Apps::EmailSettings',
    ABSTRACT            => 'A Perl library to Google\'s RESTful Apps API',
    AUTHOR              => 'Scott Schneider <sschneid@gmail.com>',
    VERSION_FROM        => 'lib/REST/Google/Apps/EmailSettings.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp'              => 0,
        'LWP::UserAgent'    => 0,
        'Test::More'        => 0,
        'XML::Simple'       => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'REST-Google-Apps-EmailSettings-*' },
);

