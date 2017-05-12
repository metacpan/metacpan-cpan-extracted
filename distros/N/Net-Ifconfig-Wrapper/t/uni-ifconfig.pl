#!/usr/local/bin/perl -w
# uni-ifconfig.pl
# The unified ifconfig command.
# Works the same way on FreeBSD, OpenBSD, Solaris, Linux, OS X, WinNT (from Win2K).
# Note: due of Net::Ifconfig::Wrapper limitations 'inet' and 'down' commands
# are not working on WinNT. +/-alias are working, of course.

use strict;

use Net::Ifconfig::Wrapper;

my $Usage = << 'EndOfText';
uni-ifconfig.pl         # Print this notice
    uni-ifconfig.pl -a      # Print info about all interfaces
    uni-ifconfig.pl <iface> # Print info obout specified interface
    uni-ifconfig.pl <iface> down
    # Bring specified interface down
    uni-ifconfig.pl <iface> inet <AAA.AAA.AAA.AAA> mask <MMM.MMM.MMM.MMM>
    # Set the specified address on the specified interface
    # and bring this interface up
    uni-ifconfig.pl <iface> inet <AAA.AAA.AAA.AAA> mask <MMM.MMM.MMM.MMM> [+]alias
    # Set the specified alias address
    # on the specified interface
    uni-ifconfig.pl <iface> inet <AAA.AAA.AAA.AAA> [mask <MMM.MMM.MMM.MMM>] -alias
    # Remove specified alias address
    # from the specified interface
    EndOfText
    
    my $Info = Net::Ifconfig::Wrapper::Ifconfig('list', '', '', '')
    or die $@;

scalar(keys(%{$Info}))
    or die "No one interface found. Something wrong?\n";

if (!scalar(@ARGV))
{
    print $Usage;
    exit 0;
}

if ($ARGV[0] eq '-a')
{
    defined($ARGV[1])
	and die $Usage;
    foreach (sort(keys(%{$Info})))
    { print IfaceInfo($Info, $_); };
    exit 0;
};

$Info->{$ARGV[0]}
or die "Interface '$ARGV[0]' is unknown\n";

if    (!defined($ARGV[1]))
{
    print IfaceInfo($Info, $ARGV[0]);
    exit 0;
}

my $CmdLine = join(' ', @ARGV);
my $Result = undef;

if    ($CmdLine =~ m/\A\s*([\w\{\}\-]+)\s+down\s*\Z/i)
{
    $Result = Net::Ifconfig::Wrapper::Ifconfig('down', $1, '', '');
}
elsif ($CmdLine =~ m/\A\s*([\w\{\}\-]+)\s+inet\s+(\d{1,3}(?:\.\d{1,3}){3})\s+mask\s+(\d{1,3}(?:\.\d{1,3}){3})\s*\Z/i)
{
    $Result = Net::Ifconfig::Wrapper::Ifconfig('inet', $1, $2, $3);
}
elsif ($CmdLine =~ m/\A\s*([\w\{\}\-]+)\s+inet\s+(\d{1,3}(?:\.\d{1,3}){3})\s+mask\s+(\d{1,3}(?:\.\d{1,3}){3})\s+\+?alias\s*\Z/i)
{
    $Result = Net::Ifconfig::Wrapper::Ifconfig('+alias', $1, $2, $3);
}
elsif ($CmdLine =~ m/\A\s*([\w\{\}\-]+)\s+inet\s+(\d{1,3}(?:\.\d{1,3}){3})\s+(:?mask\s+(\d{1,3}(?:\.\d{1,3}){3})\s+)?\-alias\s*\Z/i)
{
    $Result = Net::Ifconfig::Wrapper::Ifconfig('-alias', $1, $2, '');
}
else
{ die $Usage; };

$Result
    or die $@;

sub IfaceInfo
{
    my ($Info, $Iface) = @_;
    
    my $Res = "$Iface:\t".($Info->{$Iface}{'status'} ? 'UP' : 'DOWN')."\n";
    
    while (my ($Addr, $Mask) = each(%{$Info->{$Iface}{'inet'}}))
    { $Res .= sprintf("\tinet %-15s mask $Mask\n", $Addr); };
    
    $Info->{$Iface}{'ether'}
    and $Res .= "\tether ".$Info->{$Iface}{'ether'}."\n";
    
    $Info->{$Iface}{'descr'}
    and $Res .= "\tdescr '".$Info->{$Iface}{'descr'}."'\n";
    
    return $Res;
};

__END__
