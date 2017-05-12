use ExtUtils::MakeMaker;

die 'OS unsupported! Sorry, but this system seems not to be a linux system!'
   unless $^O =~ /linux/i;

die 'OS unsupported! Stupid! RTFM and gimme me access to /proc ;-)'
   unless -r '/proc';

WriteMakefile
(
    NAME            => 'Sys::Statistics::Linux',
    VERSION_FROM    => 'lib/Sys/Statistics/Linux.pm',
    PREREQ_PM       => {
        'UNIVERSAL::require' => 0,
        'UNIVERSAL'          => 0,
        'Test::More'         => 0,
        'Carp'               => 0,
        'POSIX'              => 0,
        'Time::HiRes'        => 0,
    },
    INSTALLDIRS     => 'site',
    EXE_FILES       => [ ],
    PL_FILES        => { }
);
