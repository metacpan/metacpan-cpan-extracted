use strict;
use warnings;
use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::SMTP::Pipelining',
    AUTHOR              => 'Marc Beyer <japh@tirwhan.org>',
    VERSION_FROM        => 'lib/Net/SMTP/Pipelining.pm',
    ABSTRACT_FROM       => 'lib/Net/SMTP/Pipelining.pm',
    PL_FILES            => {},
    PREREQ_PM => {
                  'Test::More' => 0,
                  'version'    => 0,
                  'Net::Cmd'   => 0,
                  'Net::SMTP'  => 0,
                  'IO::Socket' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-SMTP-Pipelining-*' },
);
