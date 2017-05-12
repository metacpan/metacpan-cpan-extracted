#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                    => 'MogileFS-Plugin-MetaData',
    VERSION_FROM            => 'lib/MogileFS/Plugin/MetaData.pm',
    AUTHOR                  => 'Jonathan Steinert <hachi@cpan.org>',
    ABSTRACT                => 'Plugin for mogilefs server to store arbitrary metadata with a particular fid..',
    PREREQ_PM               => {
        'MogileFS::Server'    => '2.08',
    },
);

