use ExtUtils::MakeMaker;
use Config;

WriteMakefile(
    'NAME'          => 'Term::StatusBar',
    'DISTNAME'      => 'Term-StatusBar',
    'VERSION_FROM'  => 'lib/Term/StatusBar.pm',
    'AUTHOR'        => 'Shay Harding <sharding@ccbill.com>',
    'ABSTRACT'      => 'Terminal progress bar',
    'PREREQ_PM'     => {
							"Term::Size"		=> '.2',
					   },
    'DEFINE'        => '',
    'INC'           => '',
    'dist'          => { COMPRESS => "gzip -9", SUFFIX => "gz" }
);
