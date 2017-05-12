use strict;
use warnings;
use ExtUtils::MakeMaker;

my @libs = ( "Test::More" , "Module::Pluggable::Ordered" );

if( $^O eq "MSWin32" )
{
	my $answer = prompt( "Do you want to install SystemTray::Applet::Win32?" , "y" );
	if( $answer =~ /y/i )
	{
		push( @libs , "SystemTray::Applet::Win32" );
	}
}
else
{
	my $answer = prompt( "Do you want to install SystemTray::Applet::Gnome?" , "y" );
	if( $answer =~ /y/i )
	{	
		push( @libs , "SystemTray::Applet::Gnome" );
	}
}

WriteMakefile(
    NAME                => 'SystemTray::Applet',
    AUTHOR              => 'Peter Sinnott <psinnott@cpan.org>',
    VERSION_FROM        => 'lib/SystemTray/Applet.pm',
    ABSTRACT_FROM       => 'lib/SystemTray/Applet.pm',
    PL_FILES            => {},
    PREREQ_PM => {
		map { $_ => 0 } @libs
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SystemTray-Applet-*' },
);
