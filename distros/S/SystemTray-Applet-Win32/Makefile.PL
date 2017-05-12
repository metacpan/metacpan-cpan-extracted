use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SystemTray::Applet::Win32',
    AUTHOR              => 'Peter Sinnott <psinnott@cpan.org>',
    VERSION_FROM        => 'lib/SystemTray/Applet/Win32.pm',
    ABSTRACT_FROM       => 'lib/SystemTray/Applet/Win32.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0, 'Win32::GUI' => 0 , 'SystemTray::Applet' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SystemTray-Applet-Win32-*' },
);
