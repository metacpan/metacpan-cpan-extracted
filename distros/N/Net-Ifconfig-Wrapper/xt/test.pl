# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 5 };

$^W++;

my %IfCfgCmd = ('freebsd' => '/sbin/ifconfig -a',
                'solaris' => '/sbin/ifconfig -a',
                'openbsd' => '/sbin/ifconfig -A',
                'linux'   => '/sbin/ifconfig -a',
                'darwin'  => '/sbin/ifconfig -a',
               );

print 'Loading Net::Ifconfig::Wrapper........';

use Net::Ifconfig::Wrapper;

ok(1); # If we made it this far, we're ok.



print 'Geting information about interfaces...';

my $Info = Net::Ifconfig::Wrapper::Ifconfig('list')
	or die $@;

ok(1);

if ($IfCfgCmd{$^O})
	{
	print "\n== '".$IfCfgCmd{$^O}. "' command output ==\n";
	system($IfCfgCmd{$^O});
	print "======================================\n";
	};

print "\n== Net\:\:Ifconfig\:\:Wrapper info output ==\n";
foreach (sort(keys(%{$Info})))
	{ print IfaceInfo($Info, $_); };
print "======================================\n";

print "Is Net\:\:Ifconfig\:\:Wrapper info output correct? Y/N:";

while (<STDIN>)
	{
	$_ =~ m/\A\s*y(es)?\s*\n?\Z/i
		and last;
	$_ =~ m/\A\s*n(o)?\s*\n?\Z/i
		and die "Net\:\:Ifconfig\:\:Wrapper info is incorrect!";
	print "Is Net\:\:Ifconfig\:\:Wrapper info output correct? Y/N:";
	};

print "\nInformation displayed correctly.......";

ok(1);



if (($^O eq "MSWin32") || ($> == 0))
	{
	print "\nPlease choose the interface for add/remove alias function test\n";
	
	my @Ifaces = ('skip test');
	
	push(@Ifaces, sort(keys(%{$Info})));
	
	my $DefIface = '';
	
	for (my $RI = 0; defined($Ifaces[$RI]); $RI++)
		{
		(($Ifaces[$RI] =~ m/\Alo/i) && !length($DefIface))
			and $DefIface = $RI;
		print "$RI:\t".$Ifaces[$RI]."\n";
		};
	
	print "($DefIface):";
	
	while (<STDIN>)
		{
		if    (($_ =~ m/\A\s*\n?\Z/i) && length($DefIface))
			{ last; }
		elsif (($_ =~ m/\A\s*(\d+)\s*\n?\Z/i) && defined($Ifaces[$1]))
			{
			$DefIface = $1;
			last;
			};
		print "Please choose the interface for add/remove alias function tests\n";
		for (my $RI = 0; defined($Ifaces[$RI]); $RI++)
			{ print "$RI:\t".$Ifaces[$RI]."\n"; };
		print "($DefIface):";
		};
	
	if (!$DefIface)
		{
		print "add/remove alias function tests (4,5) skipped\n";
		exit 0;
		};
	
	my $Addr = '192.168.192.168';
	my $Mask = '255.255.255.0';
	
	print "Please choose address and mask for test alias\n($Addr:$Mask):";
	
	while (<STDIN>)
		{
		$_ =~ m/\A\s*\n?\Z/i
			and last;
		if ($_ =~ m/\A\s*(\d{1,3}(?:\.\d{1,3}){3})\s*\:?\s*(\d{1,3}(?:\.\d{1,3}){3})\s*\n?\Z/i)
			{
			$Addr = $1;
			$Mask = $2;
			last;
			};
		print "Please choose address and mask for test alias\n($Addr:$Mask):";
		};
	print "\nAdding   alias '$Addr:$Mask' to   interface ".$Ifaces[$DefIface]."...";
	
	Net::Ifconfig::Wrapper::Ifconfig('+alias', $Ifaces[$DefIface], $Addr, $Mask)
		or die $@;
	
	$Info = Net::Ifconfig::Wrapper::Ifconfig('list')
		or die $@;
	
	defined($Info->{$Ifaces[$DefIface]}->{'inet'}->{$Addr}) &&
		($Info->{$Ifaces[$DefIface]}->{'inet'}->{$Addr} eq $Mask)
		or die "Can not find recently added address '$Addr:$Mask' on interface ".$Ifaces[$DefIface];
	
	ok(1);
	
	print "Removing alias '$Addr:$Mask' from interface ".$Ifaces[$DefIface]."...";
	
	Net::Ifconfig::Wrapper::Ifconfig('-alias', $Ifaces[$DefIface], $Addr, '')
		or die $@;
	
	$Info = Net::Ifconfig::Wrapper::Ifconfig('list')
		or die $@;
	
	defined($Info->{$Ifaces[$DefIface]}->{'inet'}->{$Addr})
		and die "Can not remove recently added address '$Addr:$Mask' from interface ".$Ifaces[$DefIface];
	
	ok(1);
	}
else
	{
	print "add/remove alias function tests (4,5) skipped: insufficient privileges\n";
	exit 0;
	};

#exit 0;

sub IfaceInfo
	{
	my ($Info, $Iface) = @_;

	my $Res = "$Iface:\t".($Info->{$Iface}->{'status'} ? 'UP' : 'DOWN')."\n";

	while (my ($Addr, $Mask) = each(%{$Info->{$Iface}->{'inet'}}))
		{ $Res .= sprintf("\tinet %-15s mask $Mask\n", $Addr); };
	
	$Info->{$Iface}->{'ether'}
		and $Res .= "\tether ".$Info->{$Iface}->{'ether'}."\n";

	$Info->{$Iface}->{'descr'}
		and $Res .= "\tdescr '".$Info->{$Iface}->{'descr'}."'\n";
	
	return $Res;
	};