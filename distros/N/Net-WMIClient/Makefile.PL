use 5.008000;
use ExtUtils::MakeMaker qw(prompt WriteMakefile);

my $WMI_SOURCE = prompt("Enter the path to the WMI source code:");
if (-d $WMI_SOURCE) {
	if (-d "$WMI_SOURCE/Samba/source") {
		$WMI_SOURCE = "$WMI_SOURCE/Samba/source";
	}

	my $WMI_VERSION;
	if (-f "$WMI_SOURCE/version.h") {
		$WMI_VERSION = `grep SAMBA_VERSION_STRING $WMI_SOURCE/version.h`;
	}

	if ($WMI_VERSION =~ /#define SAMBA_VERSION_STRING "(.*)"/) {
		print "WMI from Samba version $1 found\n";
	} else {
		die "Could not find properly configured WMI source code.  Please run 'make build' in the WMI source tree and install lib_async_wmilib.so.0 to build and install Net::WMIClient.";
	}

} else {

	die "WMI source location not specified or not found.  Please specify the location of the WMI source code when prompted.";

}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::WMIClient',
    VERSION_FROM      => 'lib/Net/WMIClient.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/WMIClient.pm', # retrieve abstract from module
       AUTHOR         => 'Joshua Megerman <josh@honorablemenschen.com>') : ()),
    LIBS              => ['-lasync_wmi_lib -lpopt'],
    INC               => "-I$WMI_SOURCE/lib/replace -I$WMI_SOURCE/heimdal_build -I$WMI_SOURCE/heimdal/lib/gssapi -I$WMI_SOURCE/include -I$WMI_SOURCE -I$WMI_SOURCE/lib",
    EXE_FILES         => ['script/wmic.pl'],
    LICENSE           => 'GPLv2+',
);
