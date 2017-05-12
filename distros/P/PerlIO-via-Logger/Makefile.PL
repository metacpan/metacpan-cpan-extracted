require 5.008;
use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;

warn <<END unless $Config{useperlio};
	*********************    WARNING    **********************
	This module requires a Perl with perlio support, but your
	Perl does not have this!

	This module will almost certinly not function correctly.
END

WriteMakefile(
    NAME                => 'PerlIO::via::Logger',
    AUTHOR              => 'Adam Kaplan <akaplan@cpan.org>',
    VERSION_FROM        => 'lib/PerlIO/via/Logger.pm',
    ABSTRACT		=> 'PerlIO layer for prefixing date/time stamps',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'	=> 0,
        'POSIX' 	=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PerlIO-via-Logger-*' },
);
