#!/usr/bin/perl
#
#
#
use strict;
use Data::Dumper;
use Parse::CPinfo;

my $p = Parse::CPinfo->new();
my $fn = $ARGV[0] || '../t/cpinfos/small.cpinfo';

$p->readfile($fn);

print "Here is a list of sections in the cpinfo file:\n";
foreach my $section ($p->getSectionList()) {
	print "$section\n";
}

#print "\n\n\n";
#print "List of interfaces\n";

#print "IP Interface Section\n";
#print $p->getSection('IP Interfaces');

my %eth0 = %{$p->getInterfaceInfo('eth0')};
print "eth0 hash:\n";
print Dumper(%eth0);

print '=' x 80 ."\n";
print ' ' x 33 . ' Host Report ' . ' ' x 33 . "\n";
print '=' x 80 ."\n";
print "\n";
print 'Host Name: ' . $p->getHostname() . "\n";
print "Interface    MAC Address        IP Address/Mask         MTU\n";
#print '-' x 80 ."\n";

my @interfacelist = $p->getInterfaceList();
foreach my $interface (@interfacelist) {
	my %intinfo = %{$p->getInterfaceInfo($interface)};
	print sprintf('%-9s   %-17s   %-19s   %5s', $interface, $intinfo{'hwaddr'}, "$intinfo{'inetaddr'}/$intinfo{'masklength'}", $intinfo{'mtu'});
	print "\n";
}





