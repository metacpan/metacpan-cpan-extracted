use strict;
use warnings;
use ExtUtils::MakeMaker;

my @libs =  ( "Test::More" , "Gtk2::TrayIcon" );
WriteMakefile(
    NAME                => 'SystemTray::Applet::Gnome',
    AUTHOR              => 'Peter Sinnott <psinnott@cpan.org>',
    VERSION_FROM        => 'lib/SystemTray/Applet/Gnome.pm',
    ABSTRACT_FROM       => 'lib/SystemTray/Applet/Gnome.pm',
    PL_FILES            => {},
    PREREQ_PM => {
	map { $_ => 0 } @libs
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SystemTray-Applet-Gnome-*' },
);
