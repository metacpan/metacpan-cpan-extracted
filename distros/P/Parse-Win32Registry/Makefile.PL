use 5.008_001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Parse::Win32Registry',
    VERSION_FROM    => 'lib/Parse/Win32Registry.pm',
    PREREQ_PM       => {
        'Carp'           => 0,
        'Data::Dumper'   => 0,
        'Encode'         => 0,
        'File::Basename' => 0,
        'Time::Local'    => 0,
        'Test::More'     => 0,
    },
    ABSTRACT_FROM   => 'lib/Parse/Win32Registry.pm',
    AUTHOR          => 'James Macfarlane',
    EXE_FILES       => [
        'bin/gtkregcompare.pl',
        'bin/gtkregscope.pl',
        'bin/gtkregview.pl',
        'bin/regclassnames.pl',
        'bin/regdiff.pl',
        'bin/regdump.pl',
        'bin/regexport.pl',
        'bin/regfind.pl',
        'bin/regml.pl',
        'bin/regmultidiff.pl',
        'bin/regscan.pl',
        'bin/regsecurity.pl',
        'bin/regshell.pl',
        'bin/regstats.pl',
        'bin/regtimeline.pl',
        'bin/regtree.pl',
        'bin/wxregcompare.pl',
        'bin/wxregscope.pl',
        'bin/wxregview.pl',
    ],
    ($ExtUtils::MakeMaker::VERSION > 6.30 ? (LICENSE => 'perl') : ()),
);
