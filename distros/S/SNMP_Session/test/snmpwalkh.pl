#!/usr/local/bin/perl
#
# File_________: snmpwalkh_test.pl
# Date_________: 12.11.2001
# Author_______: Laurent Girod  / Philip Morris Products S.A. / Neuchatel / Switzerland
# Description__: Example of uses of the new snmpwalkhash function in SNMP_util
#                With snmpwalkhash, you can customize as you like your
#                results, in a hash of hashes,
#                by oid names, oid numbers, instances, like:
#                   $hash{$host}{$name}{$inst} = $value;
#                   $hash{$host}{$oid}{$inst} = $value;
#                   $hash{$name}{$inst} = $value;
#                   $hash{$oid}{$inst} = $value;
#                   $hash{$oid.'.'.$inst} = $value;
#                   $hash{$inst} = $value;
#                   ...
# Needed_______: ActiveState Perl 620 from www.perl.com
# Modifications: 
#
########################################################################################################

use BER;
use SNMP_util "0.90";

$BER::pretty_print_timeticks = 0;	# Uptime in absolute value

my $host = shift @ARGV || &usage;
my $community = shift @ARGV || 'public';
&usage if $#ARGV >= 0;
$host = "$community\@$host" if !($host =~ /\@/);

#
#	Example 1: 
#
my $oid_name = 'system';

print "\nCollecting [$oid_name]\n";
@ret = &snmpwalk($host, $oid_name);
foreach $desc (@ret) {
    ($oid, $desc) = split(':', $desc, 2);
    print "$oid = $desc\n";
}

#
#	Example 2: snmpwalk
#
my @oid_names = ('ifType', 'ifMtu', 'ifSpeed', 'ifPhysAddress',);
	
print "\nCollecting ";
map { print "[$_]\t" } @oid_names;
print "\n";

@ret = &snmpwalk($host, @oid_names);
foreach $desc (@ret) {
    ($oid, $desc) = split(':', $desc, 2);
    print "$oid = $desc\n";
}

#
#	Example 3: snmpwalkhash
#

my %ret_hash = &snmpwalkhash($host, \&my_simple_hash, @oid_names);
foreach $oid (keys %ret_hash)
{
	foreach my $inst (sort { $a <=> $b } keys %{$ret_hash{$oid}})
	{
		printf("%15s %3s = %s\n", $oid, $inst, $ret_hash{$oid}{$inst});
	}
}

sub my_simple_hash
{
	my ($h_ref, $host, $name, $oid, $inst, $value) = @_;
	$inst =~ s/^\.+//;
	if ($name =~/ifPhysAddress/)
	{
		my $mac = '';
		map { $mac .= sprintf("%02X",$_) } unpack "CCCCCC", $value;
		$value = $mac;
	}
	$h_ref->{$name}->{$inst} = $value;
}

sub usage
{
    die "usage: $0 hostname [community]";
}
