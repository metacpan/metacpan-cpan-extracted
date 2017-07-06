#! /usr/local/bin/perl

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
	'NAME' => 'String::CRC32',
	'DISTNAME' => 'String-CRC32',
	'OBJECT' => 'CRC32.o',
	'dist'   => {COMPRESS=>'gzip', SUFFIX=>'gz'},
    'LICENSE' => 'unrestricted',
	VERSION_FROM => 'CRC32.pm',
    META_MERGE => {
        resources => {
            license    => 'https://wiki.creativecommons.org/wiki/Public_domain',
            homepage   => 'https://metacpan.org/module/String::CRC32',
            bugtracker => 'https://github.com/leejo/string-crc32/issues',
            repository => 'https://github.com/leejo/string-crc32'
        },
    },
);
