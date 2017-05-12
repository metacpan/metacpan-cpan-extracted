use ExtUtils::MakeMaker;
use FileHandle;

print "Checking for SNMP, V1.8  ";
$@ = '';
eval "use SNMP 1.8 ();";
if ($@) {
    $ok = 0;
    print("\nYou don't have installed the SNMP module, version 1.8 or",
          " later.\n");
} else {
    print "ok\n";
}

$FILE = new FileHandle;
open($FILE,">t/snmp.data");

print "\nEnter the IP address of the Device: ";
chomp($IP = <stdin>);

print "Enter the SNMP community string: ";
chomp($community = <stdin>);

print $FILE "IP = $IP\n";
print $FILE "community = $community\n";

close $FILE;


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME       		=> 'SNMP::Util',
    DISTNAME 		=> 'SNMP-Util',
    VERSION_FROM	=> 'Util.pm', # finds $VERSION
    dist        	=> { COMPRESS => "gzip", SUFFIX => "gz" },
);
