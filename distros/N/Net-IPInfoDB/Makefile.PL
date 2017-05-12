use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Net::IPInfoDB',
    'VERSION_FROM'  => 'IPInfoDB.pm',
    'PREREQ_PM'     => {
        'LWP::Simple'   => '5.0',
    },
    'clean'         => {
        'FILES' => '$(DISTVNAME).tar$(SUFFIX) *.ppd',
    },
    'dist'          => {
        PREOP => 'perldoc -t IPInfoDB.pm > README',
    },
    EXE_FILES       => [
        'ipinfodb',
    ],
    'AUTHOR'        => 'Darren Chamberlain <darren@cpan.org>',
);
