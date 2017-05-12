#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                    => 'MogileFS-Client-FilePaths',
    VERSION_FROM            => 'lib/MogileFS/Client/FilePaths.pm',
    AUTHOR                  => 'Jonathan Steinert <hachi@cpan.org>',
    ABSTRACT                => 'Subclass of MogileFS::Client that provides additional helper functions for with the FilePaths plugin in mogilefsd.',
    PREREQ_PM               => {
        'MogileFS::Client'    => '0',
    },
);

