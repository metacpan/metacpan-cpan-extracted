use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Postgres::Handler::HTML',
    AUTHOR              => 'Cyber Sprocket Labs <info@cybersprocket.com>',
    VERSION_FROM        => 'lib/Postgres/Handler/HTML.pm',
    ABSTRACT_FROM       => 'lib/Postgres/Handler/HTML.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Postgres::Handler' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Postgres-Handler-HTML-*' },
);
