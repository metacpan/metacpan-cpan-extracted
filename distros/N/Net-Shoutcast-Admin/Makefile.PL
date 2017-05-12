# $Id: Makefile.PL 315 2008-03-19 00:07:39Z davidp $
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Shoutcast::Admin',
    AUTHOR              => 'David Precious <davidp@preshweb.co.uk>',
    VERSION_FROM        => 'lib/Net/Shoutcast/Admin.pm',
    ABSTRACT_FROM       => 'lib/Net/Shoutcast/Admin.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'     => 0,
        'version'        => 0,
        'URI::Escape'    => 0,
        'LWP::UserAgent' => 0,
        'XML::Simple'    => 0,
    },
    NO_META             => 1,
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Shoutcast-Admin-*' },
);
