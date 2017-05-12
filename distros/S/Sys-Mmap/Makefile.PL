use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Sys::Mmap',
    AUTHOR              => 'Scott Walters <swalters@cpan.org>',
    VERSION_FROM        => 'Mmap.pm',
    ABSTRACT_FROM       => 'Mmap.pm',
    PL_FILES            => {},
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'        => 'perl', ) : ()),
    PREREQ_PM => {
        ($] >= 5.006 ? ('XSLoader' => 0) : ()),  
        'DynaLoader' => 0,
	'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Sys-Mmap-*' },
    META_MERGE  => {
        build_requires => {
            'Test::More' => 0,  # For testing
	    'Errno' => 0, # Locale independant failure validation.
        },
        resources => {
            license => 'http://dev.perl.org/licenses/',
#            homepage => 'http://wiki.github.com/toddr/Sys-Mmap',
            bugtracker => 'https://github.com/toddr/Sys-Mmap/issues',
            repository => 'http://github.com/toddr/Sys-Mmap/tree/master',
#            MailingList => 'http://groups.google.com/group/Sys-Mmap',
        },
    },
);
