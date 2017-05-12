#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI::Hardware::Net                       #
# Class:       Interface                                            #
# Description: Methods for building a Router (Stanford) style CLI   #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-04-27                                           #
##################################################################### 
#
#
#
#
package Term::RouterCLI::Hardware::Net::Interface;

use 5.8.8;
use strict;
use warnings;
use Term::RouterCLI::Config;
use Term::RouterCLI::Debugger;
use Log::Log4perl;

our $VERSION     = '1.00';
$VERSION = eval $VERSION;

# Define our parent
use parent qw(Term::RouterCLI::Hardware::Net);


my $oDebugger = new Term::RouterCLI::Debugger();
my $oConfig = new Term::RouterCLI::Config();
# TODO move this to the configuration file
my $ethtool = './bin/ethtool';


sub GetInterfaceList
{
    # This method will get a list of all avaliable interface on the system.  We will check the configuration 
    # file for any excluded interfaces.  
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    my $config = $oConfig->GetRunningConfig();
    
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###'); 
    
    my @aInterfacesProcData = `cat /proc/net/dev`;
    splice (@aInterfacesProcData, 0, 2);
    foreach (@aInterfacesProcData)
    {
        s/^\s+//g;
        s/\s+$//g;
        my ($key, $value) = split (":", $_);

        # There are some interface that we will want to skip so lets flag them as disabled
        if (exists $config->{'system'}->{'excluded_interfaces'}->{$key}) { $self->{'_hInterfaces'}->{$key}->{'enabled'} = 0; }
        else { $self->{'_hInterfaces'}->{$key}->{'enabled'} = 1; }
    }
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

sub GetInterfaceDetails
{
    # This method will get the interface details for a single interface
    # Required:
    #   string (interface name)
    # Return:
    #   hash_ref (string details and stats)
    my $self = shift;
    my $sInterfaceName = shift;
    my $logger = $oDebugger->GetLogger($self);
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###'); 

    # Just some sanity verification
    unless (defined $sInterfaceName) { $sInterfaceName = "eth0"; }

    # Lets set all initial values so the printf lines do not complain if the interface does not in fact
    # have all of the data we expect.
    my $hIntDetails = {};
    $hIntDetails->{'name'} = $sInterfaceName;
    $hIntDetails->{'mac_address'} = "";
    $hIntDetails->{'link_status'} = "";
    $hIntDetails->{'speed'} = "";
    $hIntDetails->{'duplex'} = "";
    $hIntDetails->{'port'} = "";
    $hIntDetails->{'auto_negotiation'} = "";
    $hIntDetails->{'link_detected'} = "";
    $hIntDetails->{'rx_bytes'} = 0;
    $hIntDetails->{'tx_bytes'} = 0;
    $hIntDetails->{'rx_packets'} = 0;
    $hIntDetails->{'tx_packets'} = 0;
    $hIntDetails->{'rx_broadcast'} = 0;
    $hIntDetails->{'tx_broadcast'} = 0;
    $hIntDetails->{'rx_multicast'} = 0;
    $hIntDetails->{'tx_multicast'} = 0;
    $hIntDetails->{'rx_frame_errors'} = 0;
    $hIntDetails->{'rx_crc_errors'} = 0;
    $hIntDetails->{'rx_align_errors'} = 0;
    $hIntDetails->{'rx_over_errors'} = 0;
    $hIntDetails->{'rx_short_length_errors'} = 0;
    $hIntDetails->{'rx_long_length_errors'} = 0;
    $hIntDetails->{'rx_errors'} = 0;
    $hIntDetails->{'tx_carrier_errors'} = 0;
    $hIntDetails->{'tx_window_errors'} = 0;
    $hIntDetails->{'tx_dropped'} = 0;
    $hIntDetails->{'tx_aborted_errors'} = 0;
    $hIntDetails->{'tx_fifo_errors'} = 0;
    $hIntDetails->{'tx_heartbeat_errors'} = 0;
    $hIntDetails->{'collisions'} = 0;
    $hIntDetails->{'tx_errors'} = 0;

    
    # Lets try and get data from /proc/net/dev as ethtool does not have support for all interface types.  
    my @aInterfaceProcData = `cat /proc/net/dev`;
    splice (@aInterfaceProcData, 0, 2);
    foreach (@aInterfaceProcData)
    {
        # Get rid of whitespace
        s/^\s+//g;
        s/\s+$//g;
        my ($key, $value) = split (":", $_);
        unless ($key eq $sInterfaceName) {next;}
        
        # Lets make sure there is not any extra spaces between values
        $value =~ s/\s+/ /g;
        my @aInterfaceProcStats = split (" ", $value);
        $hIntDetails->{rx_bytes} = $aInterfaceProcStats[0];
        $hIntDetails->{rx_packets} = $aInterfaceProcStats[1];
        $hIntDetails->{rx_errors} = $aInterfaceProcStats[2];
        # drop = rx_dropped +  rx_missed_errors from ethtool
        $hIntDetails->{rx_over_errors} = $aInterfaceProcStats[4];
        # frame errors = rx_length_errors + rx_over_errors +  rx_crc_errors + rx_frame_errors from ethtool
        # compressed
        $hIntDetails->{rx_multicast} = $aInterfaceProcStats[7];
        $hIntDetails->{tx_bytes} = $aInterfaceProcStats[8];
        $hIntDetails->{tx_packets} = $aInterfaceProcStats[9];
        $hIntDetails->{tx_errors} = $aInterfaceProcStats[10];
        $hIntDetails->{tx_dropped} = $aInterfaceProcStats[11];
        $hIntDetails->{tx_fifo_errors} = $aInterfaceProcStats[12];
        $hIntDetails->{collisions} = $aInterfaceProcStats[13];
        # tx carrier errors = tx_carrier_errors + tx_aborted_errors + tx_window_errors + tx_heartbeat_errors from ethtool
        # compressed
    }
    
    # Now lets get stat data from ethtool and we will only use the ethtool data for stats if the value is still 0
    my @aInterfaceStats = eval{ `$ethtool -S $sInterfaceName` };
    foreach (@aInterfaceStats)
    {
        s/^\s+//g;  
        s/\s+$//g;
        if (/^.*NIC.*/) {next;} 
        my ($key, $value) = split (": ", $_); 
        if (defined $value && (exists $hIntDetails->{$key} && $hIntDetails->{$key} == 0 )) { $hIntDetails->{$key} = $value; }
    }

    # Lets get general interface details
    my @aInterfaceDetails = `$ethtool $sInterfaceName`;    
    foreach (@aInterfaceDetails)
    {
        s/^\s+//g;  
        s/\s+$//g;
        my ($key, $value) = split (": ", $_);
        # If there are spaces in the key name lets replace them with underscores
        # also, lets change the key to be all lower case.
        $key =~ s/ /_/g;
        $key = lc($key);
        # If there are any "-" values in the keys, lets replace them with "_"
        $key =~ s/-/_/g;
        if (defined $value) { $hIntDetails->{$key} = $value; }
        else { $hIntDetails->{$key} = "0"; }
    }
    
    # Lets get the mac address for the interface
    my @aInterfaceMACAddress = `$ethtool -P $sInterfaceName`;
    $aInterfaceMACAddress[0] =~ s/^\s+//g;
    $aInterfaceMACAddress[0] =~ s/\s+$//g;  
    $hIntDetails->{mac_address} = (split ": ", $aInterfaceMACAddress[0])[1];
    
    
    if (exists $hIntDetails->{link_detected} && $hIntDetails->{link_detected} eq "yes") { $hIntDetails->{link_status} = "Up";}
    else { $hIntDetails->{link_status} = "Down";}

    # Add the interface details to the object
    $self->{'_hInterfaces'}->{$sInterfaceName}->{'details'} = $hIntDetails;

    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

sub PrintInterfaceDetails
{
    # This method will print the interface details for a single interface
    # Required:
    #   hash_ref (interface details and stats)
    my $self = shift;
    my $sInterfaceName = shift;
    my $logger = $oDebugger->GetLogger($self);
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###'); 
    
    my $hInterface = $self->{'_hInterfaces'}->{$sInterfaceName}->{'details'};

    print "\n";
    print "$hInterface->{name} is $hInterface->{link_status}\n";
    print "  Hardware is $hInterface->{port}, address is $hInterface->{mac_address}\n";
    if ($hInterface->{auto_negotiation} eq "on") {
        print "  Configured speed auto, actual $hInterface->{speed}, configured duplex auto, actual $hInterface->{duplex}\n";
    }
    else {
        print "  Configured speed $hInterface->{speed}, actual $hInterface->{speed}, configured duplex $hInterface->{duplex}, actual $hInterface->{duplex}\n";        
    }
    print "  Received $hInterface->{rx_bytes} bytes, $hInterface->{rx_packets} packets, $hInterface->{rx_broadcast} broadcast, $hInterface->{rx_multicast} multicast\n";
    print "  $hInterface->{rx_errors} input errors, $hInterface->{rx_frame_errors} frame, $hInterface->{rx_crc_errors} crc, $hInterface->{rx_align_errors} alignment, $hInterface->{rx_over_errors} overruns, $hInterface->{rx_short_length_errors} runts, $hInterface->{rx_long_length_errors} giants\n";
    print "  Transmited $hInterface->{tx_bytes} bytes, $hInterface->{tx_packets} packets, $hInterface->{tx_broadcast} broadcast, $hInterface->{tx_multicast} multicast\n";
    print "  $hInterface->{tx_errors} output errors, $hInterface->{tx_carrier_errors} carrier, $hInterface->{tx_window_errors} window, $hInterface->{tx_dropped} dropped, $hInterface->{tx_aborted_errors} aborted, $hInterface->{tx_fifo_errors} fifo, $hInterface->{collisions} collisions\n";
    print "\n";

    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

sub PrintInterfaceDetailsTabbed
{
    # This method will print the interface details for a single interface
    # Required:
    #   hash_ref (interface details and stats)
    my $self = shift;
    my $sInterfaceName = shift;
    my $logger = $oDebugger->GetLogger($self);
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###'); 
    
    unless (defined $sInterfaceName) { return 0; }

    if ( exists $self->{'_hInterfaces'}->{$sInterfaceName} && $self->{'_hInterfaces'}->{$sInterfaceName}->{'enabled'} == 1 )
    {
        $self->GetInterfaceDetails($sInterfaceName);
        my $hInterface = $self->{'_hInterfaces'}->{$sInterfaceName}->{'details'};
        
        print "\nInterface Details\n";
        printf "    %-15s : %18s       %-15s : %18s\n", "Name",           "$hInterface->{'name'}",                   "Speed",     "$hInterface->{'speed'}";
        printf "    %-15s : %18s       %-15s : %18s\n", "Status",         "$hInterface->{'link_status'}",            "Duplex",     "$hInterface->{'duplex'}";
        printf "    %-15s : %18s       %-15s: %18s\n", "MAC Address",    "$hInterface->{'mac_address'}",            "Auto-Negotiation",     "$hInterface->{'auto_negotiation'}";
        print "\n";
        print "  Transmit Totals\n";
        printf "    %-15s : %18d       %-15s : %18d\n", "Bytes Rx",       "$hInterface->{'rx_bytes'}",               "Bytes Tx",     "$hInterface->{'tx_bytes'}";
        printf "    %-15s : %18d       %-15s : %18d\n", "Frmaes Rx",      "$hInterface->{'rx_packets'}",             "Frames Tx",   "$hInterface->{'tx_packets'}";
        printf "    %-15s : %18d       %-15s : %18d\n", "Broadcast Rx",   "$hInterface->{'rx_broadcast'}",           "Broadcast Tx", "$hInterface->{'tx_broadcast'}";
        printf "    %-15s : %18d       %-15s : %18d\n", "Multicast Rx",   "$hInterface->{'rx_multicast'}",           "Multicast Tx", "$hInterface->{'tx_multicast'}";
        print "\n";
        printf "  %-15s   : %18d       %-15s : %18d\n", "Recieve Errors", "$hInterface->{'rx_errors'}",            "Transmit Errors", "$hInterface->{'tx_errors'}";
        printf "    %-15s : %18d       %-15s : %18d\n", "Frame Rx",     "$hInterface->{'rx_frame_errors'}",        "  Carrier Tx",      "$hInterface->{'tx_carrier_errors'}";
        printf "    %-15s : %18d       %-15s : %18d\n", "Align Rx",     "$hInterface->{'rx_align_errors'}",        "  Dropped Tx",      "$hInterface->{'tx_dropped'}";
        printf "    %-15s : %18d       %-15s : %18d\n", "Runts Rx",     "$hInterface->{'rx_short_length_errors'}", "  FIFO Tx",         "$hInterface->{'tx_fifo_errors'}";
        printf "    %-15s : %18d       %-15s : %18d\n", "CRC Rx",       "$hInterface->{'rx_crc_errors'}",          "  Window Tx",       "$hInterface->{'tx_window_errors'}";
        printf "    %-15s : %18d       %-15s : %18d\n", "Over Rx",      "$hInterface->{'rx_over_errors'}",         "  Aborted Tx",      "$hInterface->{'tx_aborted_errors'}";
        printf "    %-15s : %18d       %-15s : %18d\n", "Giants Rx",    "$hInterface->{'rx_long_length_errors'}",  "  Collisions Tx",   "$hInterface->{'collisions'}";
        print "\n";
    }
    else { print "Interface not found!\n"; }
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

sub PrintInterfaceBrief
{
    # This method will print out a single summary line for an interface
    # Required:
    #   hash_ref (interface details and stats)
    my $self = shift;
    my $sInterfaceName = shift;
    my $logger = $oDebugger->GetLogger($self);
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###'); 
    
    unless (defined $sInterfaceName) { return 0; }

    if ( exists $self->{'_hInterfaces'}->{$sInterfaceName} && $self->{'_hInterfaces'}->{$sInterfaceName}->{'enabled'} == 1 )
    {
        $self->GetInterfaceDetails($sInterfaceName);
        my $hInterfaceDetails = $self->{'_hInterfaces'}->{$sInterfaceName}->{'details'};
        
        my $iTotalBytes = $hInterfaceDetails->{'rx_bytes'} + $hInterfaceDetails->{'tx_bytes'};
        my $iTotalFrames = $hInterfaceDetails->{'rx_packets'} + $hInterfaceDetails->{'tx_packets'};
        printf " %-10s %-5s %18d %18d %12d %12d\n", "$hInterfaceDetails->{'name'}", "$hInterfaceDetails->{'link_status'}", "$iTotalBytes", "$iTotalFrames", "$hInterfaceDetails->{'rx_errors'}", "$hInterfaceDetails->{'tx_errors'}";
    }
    elsif ( !exists $self->{'_hInterfaces'}->{$sInterfaceName} ) { print "Interface not found!\n"; }
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
    return 1;
}

sub PrintInterfaceBriefHeader
{
    # This method will print the header for the "brief" output
    my $self = shift;
    my $logger = $oDebugger->GetLogger($self);
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###'); 
    
    print "Status and Counters - Interface Counters\n";
    print "\n";
    printf " %-10s %-5s %18s %18s %12s %12s\n", "Port", "Link", "Total Bytes", "Total Frames", "Rx Errors", "Tx Errors";
    printf " %-10s %-5s %18s %18s %12s %12s\n", "----------", "-----", "------------------", "------------------", "------------", "------------";    
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

sub PrintAllInterfacesNormal
{
    # This method will print out all interface stats
    # Required:
    #   string (display type);
    my $self = shift;
    my $sDisplayType = shift;
    my $logger = $oDebugger->GetLogger($self);
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###'); 
    
    foreach (sort(keys(%{$self->{'_hInterfaces'}})))
    {
        if ( $self->{'_hInterfaces'}->{$_}->{'enabled'} == 1 )
        {
            $self->GetInterfaceDetails($_);
            $self->PrintInterfaceDetails($_);            
        }
    }
    print "\n";
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

sub PrintAllInterfacesBrief
{
    # This method will print out all interface stats
    # Required:
    #   string (display type);
    my $self = shift;
    my $sDisplayType = shift;
    my $logger = $oDebugger->GetLogger($self);
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###'); 
    
    $self->PrintInterfaceBriefHeader();
    foreach (sort(keys(%{$self->{'_hInterfaces'}})))
    {
        $self->PrintInterfaceBrief($_);
    }
    print "\n";
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}

sub ShowInterface 
{
    # This method will print out the interface details if the interface is found, else it will
    # print out a summary of all interfaces
    # Required:
    #   string (interface name, ex eth0)
    my $self = shift;
    my $sDisplayType = shift;
    my $sInterfaceName = shift;
    my $logger = $oDebugger->GetLogger($self);
    $logger->debug("$self->{'_sName'} - ", '### Entering Method ###'); 
    
    unless (defined $sDisplayType) { $sDisplayType = "normal"; }

    # We need a list of all valid interfaces for this system
    $self->GetInterfaceList();
    
    if ($sDisplayType eq "normal" && defined $sInterfaceName )      { $self->PrintInterfaceDetailsTabbed($sInterfaceName); }
    elsif ($sDisplayType eq "normal" && !defined $sInterfaceName)   { $self->PrintAllInterfacesNormal(); }
    elsif ($sDisplayType eq "brief" && !defined $sInterfaceName)    { $self->PrintAllInterfacesBrief(); }
    elsif ($sDisplayType eq "brief" && defined $sInterfaceName) 
    { 
        $self->PrintInterfaceBriefHeader();
        $self->PrintInterfaceBrief($sInterfaceName)
    }
    
    else { print "Interface not found!\n"; }
    $logger->debug("$self->{'_sName'} - ", '### Leaving Method ###');
}


return 1;
