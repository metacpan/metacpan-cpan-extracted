package Storage::Nexsan::NMP;

use strict;
use warnings;
use v5.10; #make use of the say command and other nifty perl 10.0 onwards goodness
use Carp;
use IO::Socket::INET;
use IO::File;
use File::Slurp;
use DateTime;
use Config::INI::Reader;

use vars qw (@ISA @EXPORT);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( 
	ConnectToNexsan AuthenticateNexsan GetEventCount ShowSystemNexsan UploadFirmwareToNexsan
	ShutdownNexsan RollingRebootNexsan TurnOffMAIDOnNexsan SetOpt);



=head1 NAME

Storage::Nexsan::NMP - The great new way to mange Nexsan's programattically!

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

This module ecapsulates version 2.30 of the Nexsan Management Protocol (NMP), written to 
automate some functions of the Nexsan storage device.  

As most commands are relatively atomic, each command will carp if it fails, unless specifically 
otherwise noted.
	
This module covers only the following functions:
	
	Status
	System Information
	Firmware upgrade
	Shutdown
	Rolling Reboot of controllers
	Event Log count
	Turning off MAID
	Setting options via SETOPT/DAT files
	
Further work will be done to implement the rest of the NMP as I require it, 
 unless anyone wants to pitch in and help...


Sample code snippet.

use Storage::Nexsan::NMP;

say "Connecting to Nexsan: $nexsan, Port: $port";           
my %NexsanInfo = ConnectToNexsan ($nexsan, $port);

my $sock = $NexsanInfo{sock};

say "Nexsan Version: " . $NexsanInfo{NMP}{Major} . "." . $NexsanInfo{NMP}{Minor} . "." . $NexsanInfo{NMP}{Patch};
say "Nexsan Serial: " . $NexsanInfo{serial};


#fill in the user and password details, then authenticate
$NexsanInfo{username} = "ADMIN";
$NexsanInfo{password} = "password";

AuthenticateNexsan (\%NexsanInfo);

GetEventCount(\%NexsanInfo); 
#this will now be populated
say "No Of Events: $NexsanInfo{eventCount}";

ShowSystemNexsan(\%NexsanInfo); 

say "Status: $NexsanInfo{status}";
say "model: $NexsanInfo{model}";
say "firmware: $NexsanInfo{firmware}";
say "friendlyname $NexsanInfo{friendlyname}";
say "vendor: $NexsanInfo{vendor}";
say	"productid 	$NexsanInfo{productid}";
say "enclosurenaaid: $NexsanInfo{enclosurenaaid}";

unless (defined $firmware) { die "no firmware value passed\n"; }
$NexsanInfo{firmwarefile} = $firmware;

UploadFirmwareToNexsan(\%NexsanInfo);

close($sock);

=head1 TODO

 * Rewrite the functions as OO - at the moment each function copies and pastes some standard functionality which is nasty and should be fixed, but out of TUITS..
 * apply some error checking for correct INI structure in SetOpt()
 * write a specific subroutine for the Powerlevel stanza (see notes in TurnOffMAIDInNexsan() )
 * write tests that tries functions not passing a $nexsan veriable
 * write tests that tries functions not passing a $port variable
 * write a test suite
 * write a Nexsan emulator that returns canned responses for the above test suite (definately in wish list territory here)


=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 ConnectToNexsan

MUST be passed IP/fqdn of Nexsan & then MAY be passed port no

Returns hash with following (example) information (thanks to Data::Dumper!);

$VAR1 = 'banner';

$VAR2 = '220 <237C2F1C> SATABeast2-059955A0-0 NMP V2.3.0 ready
';

$VAR3 = 'serial';

$VAR4 = '237C2F1C';

$VAR5 = 'NMP';

$VAR6 = {
          'Minor' => '3',
          'Major' => '2',
          'Patch' => '0'
        };
$VAR7 = 'sock';


=cut

=head2 WriteLog

internal (i.e. not exported) function that takes the %NexsanInfo hash, 
and prepends nexan name/ip and date/time to the ususal 'say' output.

it assumes that ConnectToNexsan has been run, but nothing else.

=cut

sub WriteLog {

	#assign the variables, and set defaults if not passed
	my $message;
	my ($NexsanInfo) = shift;
	#some lines (responses from NMP, usually) have newlines, some don't, so sanitise
	chomp ($message = shift); 
	

	# check we've successfully connected, as this will only be populated if we did
	if (!exists $NexsanInfo->{ip})
	{
		croak "ip not passed to Storage::Nexsan::NMP::Authenticate() - not connected?\n";
	}	

	#build the date information we are going to log
	my ($dt) = DateTime->now;
	my ($ymd)    = $dt->ymd;           # e.g. 2002-12-06
	my ($hour)   = $dt->hour;           # 0-23
	my ($minute) = $dt->minute;         # 0-59 - also min
	my ($second) = $dt->second;			# 0-61 (leap seconds!) - also sec
	my ($testtime) = $ymd . "T" .  $hour . $minute . $second;	

	#TODO really should use Log::Dispatch here, and  overload all the carp messages.
	# decision was taken to be sinple STDOUT messages to make logging via tee etc easy, and 
	# in the interestes of getting the script finished in time..
	say "$NexsanInfo->{ip} :: $testtime :: $message";

} #end of sub WriteLog


#TODO test that tries this not passing a $nexsan
#TODO test that tries this not passing a $port

=head2 ConnectToNexsan

Initial setup internal function used by all the utility functions to setup the telnet conenction

=cut

sub ConnectToNexsan {
	#MUST be passed IP/fqdn of Nexsan & MAY be passed port no
	
	#check we've got the right number of parameters
	if ( @_ < 1 || @_ > 2 )
	{
		croak "insufficient variables passed to Storage::Nexsan::NMP::ConnectToNexsan()\n";
	}
	
	#assign the variables, and set defaults if not passed
	my ($nexsanIP, $Port) = @_;
	if (!defined $nexsanIP)
	{
		croak "nexsan variable not passed to Storage::Nexsan::NMP::ConnectToNexsan()\n";
	}
	my $nexsanPort;
	
	#				if option given		Use option		Else default
	$nexsanPort = 	defined $Port			?	$Port		:	'44844';
	
	my $sock = IO::Socket::INET->new(PeerAddr => $nexsanIP,
                                 PeerPort => $nexsanPort,
                                 Timeout => 240,	#add in extra timeout for the firmware upload
                                 Proto    => 'tcp')
        or croak "Cannot connect to $nexsanIP on $nexsanPort because: $!";
        
	#get the banner prompt, which it should always provide
	my $banner = <$sock>;
	#say "banner:::: $banner";

	##setup and populate the hash to return
	my %NexsanInfo;	
	
	#sample banner line is:
	#220 <41C6167E> SATABeast2-059955A0-0 NMP V2.3.0 ready
	#
	$banner =~ m/NMP\sV(\d)\.(\d)\.(\d)\s/; #get the NMP version no
	
	$NexsanInfo{NMP}{Major} = $1;
	$NexsanInfo{NMP}{Minor} = $2;
	$NexsanInfo{NMP}{Patch} = $3;
	
	$NexsanInfo{banner} = $banner;
	$NexsanInfo{sock} = $sock;
	$NexsanInfo{ip} = $nexsanIP;
	
	$banner =~ m/<(\S+)>/; #get the NMP version no
	$NexsanInfo{serial} = $1;
	
	return %NexsanInfo; 
}


=head2 AuthenticateNexsan

Authenticates to the NMP, without which any command but QUIT will fail.

MUST be passed hash containing socket, username and password pairs, e.g.

$NexsanInfo{sock}
$NexsanInfo{username}
$NexsanInfo{password}

croak's on failure of username or password to authenticate, 
as you can't do much without being logged in

=cut

sub AuthenticateNexsan 
{

	#MUST be passed a reference to a hash containing sock, username and password pairs
	
	#assign the variables, and set defaults if not passed
	my ($NexsanInfo) = shift;
	my $sock; #can't use the hash version with say for some reason

	if (!exists $NexsanInfo->{sock})
	{
		croak "socket not passed to Storage::Nexsan::NMP::Authenticate()\n";
	}	
	else
	{
		$sock = $NexsanInfo->{sock};
	}
	if (!exists $NexsanInfo->{username})
	{
		croak "username not passed to Storage::Nexsan::NMP::Authenticate()\n";
	}	
	if (!exists $NexsanInfo->{password})
	{
		croak "password not passed to Storage::Nexsan::NMP::Authenticate()\n";
	}	
	

	### username
	say $sock "user $NexsanInfo->{username}";
	my $answer = <$sock>;

	if ( $answer =~ /^331/ )
		{
			WriteLog($NexsanInfo, "username ok: $answer");
			$NexsanInfo->{authentication}->{username} = $answer;
		}
	else
		{
			$NexsanInfo->{authentication}->{username} = $answer;
			croak "problem with the username:::: $answer";
		}



	#### password
	say $sock "pass $NexsanInfo->{password}";
	$answer = <$sock>;

	if ( $answer =~ /^230/ )
       {
                WriteLog($NexsanInfo, "password ok: $answer");
                $NexsanInfo->{authentication}->{password} = $answer;
                return 0;
        }
	else
        {
        		$NexsanInfo->{authentication}->{password} = $answer;
                croak "problem with the password:::: $answer";
        }

}
	
=head2 GetEventCount

	#MUST be passed a reference to a hash containing socket
	
	It will update the hash passed with a name:value pair called eventCount.
	It can be called as many times as you wish.

=cut

sub GetEventCount {

	#assign the variables, and set defaults if not passed
	my ($NexsanInfo) = shift;
	my $sock; #can't use the hash version with say for some reason

	if (!exists $NexsanInfo->{sock})
	{
		croak "socket not passed to Storage::Nexsan::NMP::Authenticate()\n";
	}	
	else
	{
		$sock = $NexsanInfo->{sock};
	}
	#also check we've successfully authenticated, as this will only be populated is we did
	if (!exists $NexsanInfo->{password})
	{
		croak "password not passed to Storage::Nexsan::NMP::Authenticate() - not authenticated?\n";
	}	


	say $sock "event count";
	my $answer = <$sock>;
	
	if ( $answer =~ /^2\d\d/ )
    {
	
		#say $answer;

		$answer =~ m/<(\S+)>/; #get the NMP version no
		$NexsanInfo->{eventCount} = $1;
		return 0;
	}
	else
	{
		
		$answer =~ /^(\d+)\s/;
		carp "Error: $answer\n";
	}

}

=head2 ShowSystemNexsan

	MUST be passed an reference to a hash that contains a socket, and the AuthenticateNexsan 
		subroutine must have been run beforehand to populate the other required hash's
	
	Populates hash with the following name:value pairs;
	Parameter			Description
	<status>			Status of the RAID system (“HEALTHY”, “FAULT”)
	<serial>			Serial number of the RAID system (8 hexadecimal digits)
	<model>				Model name of the RAID system
	<firmware>			Firmware version of the RAID system
	<friendlyname>		User-defined friendly name of the RAID system
	<vendor>			“T10 Vendor Identification” field as reported in SCSI INQUIRY data [NMP 2.2.0]
	<productid>			“Product Identification” field as reported in SCSI INQUIRY data [NMP 2.2.0]
	<enclosurenaaid>	“Enclosure NAA identifier” field as reported in SCSI INQUIRY VPD page 0x83 identifier type 3 [NMP 2.2.0]

=cut

sub ShowSystemNexsan {

	#assign the variables, and set defaults if not passed
	my ($NexsanInfo) = shift;
	my $sock; #can't use the hash version with say for some reason

	if (!exists $NexsanInfo->{sock})
	{
		croak "socket not passed to Storage::Nexsan::NMP::Authenticate()\n";
	}	
	else
	{
		$sock = $NexsanInfo->{sock};
	}
	#also check we've successfully authenticated, as this will only be populated if we did
	if (!exists $NexsanInfo->{password})
	{
		croak "password not passed to Storage::Nexsan::NMP::Authenticate() - not authenticated?\n";
	}	


	say $sock "show system";
	my @answer;
	my ($line, $count);
	$count = 0;
	#multi-line response, but we only care about line 0 and 1
	
	# example:
	#221 Information follows
	#SYSTEM:HEALTHY:059955A0:SATABeast2:Nj67:"nex-ge02 (SATA test)":NEXSAN:SATABeast2:6000402005FC55A0
	#.
	while ($line = <$sock>) 
	{
		push @answer, $line;
		# $line;
		#only get the lines we want, as while loop never exits otherwise
		last if $count == 2; 
		$count++;
	}
	
	
	if ( $answer[0] =~ /^2\d\d/ ) #successful command
    {
		my $dummy; #lazy way of stripping out the first variable out of the response
		($dummy, $NexsanInfo->{status}, $NexsanInfo->{serial}, 
			$NexsanInfo->{model}, $NexsanInfo->{firmware},
			$NexsanInfo->{friendlyname}, $NexsanInfo->{vendor}, 
			$NexsanInfo->{productid}, $NexsanInfo->{enclosurenaaid} ) = split (/:/, $answer[1]);

		return 0;
	}
	else
	{
		say @answer;
		#$answer =~ /^(\d+)\s/;
		carp "Error: see above\n";
	}


}

	
=head2 UploadFirmwareToNexsan

	Uploads a firmware file to the Nexsan. Requires NMP 2.3.0 or later - and this routine
		checks for that, although it is safe to issue this command to an earlier version, as 
		it will safely reject the command, according to the developer. :-)
	
	MUST be passed an reference to a hash that contains a socket, and the AuthenticateNexsan 
		subroutine must have been run beforehand to populate the other required hash's
	MUST have 
	MUST have firmware filename passed in the above hash in the above hash's firmwarefile 
		name:value, e.g. $NexsanInfo->{firmware}->{filename} .
	
	NOTE: DOES NOT reboot the system after the upgrade; you need to use another function to do that!

=cut

sub UploadFirmwareToNexsan {

	#assign the variables, and set defaults if not passed
	my ($NexsanInfo) = shift;
	my $sock; #can't use the hash version with say for some reason

	if (!exists $NexsanInfo->{sock})
	{
		croak "socket not passed to Storage::Nexsan::NMP::Authenticate()\n";
	}	
	else
	{
		$sock = $NexsanInfo->{sock};
	}
	#also check we've successfully authenticated, as this will only be populated if we did
	if (!exists $NexsanInfo->{password})
	{
		croak "password not passed to Storage::Nexsan::NMP::Authenticate() - not authenticated?\n";
	}	

	##check we've got the filename to slurp in
	if (!exists $NexsanInfo->{firmwarefile})
	{
		croak "firmware filename variable not passed to 
			Storage::Nexsan::NMP::Authenticate() - not authenticated?\n";
	}

	#WriteLog($NexsanInfo, "$NexsanInfo->{firmwarefile}");
	#test the firmware file exists & we can read it
	unless ( -e $NexsanInfo->{firmwarefile} )
	{
		croak "can't read $NexsanInfo->{firmwarefile} aborting\n";
	}


	#TODO; do we need to sanitise this with File::Basename in future?
	#slurp in the file
	my $firmwareData = read_file( $NexsanInfo->{firmwarefile} )  
		or croak "Can't read in $NexsanInfo->{firmwarefile} because $!\n"; #using File::Slurp


	#Sanity checking the version of the Nexsan Management Protocol;
	unless ($NexsanInfo->{NMP}->{Major} >= 2 && $NexsanInfo->{NMP}->{Minor} >= 3)
	{
		croak "requires NMP 2.3.0 or later to understand the MAINT FWUPLOAD command";
		#doesn't carp because presumably the purpose of running this script 
		#with this function was to actually upgrade the firmware! Feedback apprciated 
		# if this matters to you
	}
	
	#sanity checking that there are no firmware upgrades going on in practice
	WriteLog($NexsanInfo, "checking for upgrades already in progress");
	say $sock "MAINT FWSTATUS";
	my $answer = <$sock>;
	#check for the only error code that means a firmware upgrade isn't in progress or the 
	#last script/GUI may not have completed yet
	# looking for: '224 Firmware update not started or status has been reset'
	unless ( $answer =~ /^224/ ) 
	{
		croak "Firmware upgrade already in progress or status not reset: $answer\n";
	}
	#say $answer;
	
	WriteLog($NexsanInfo, "** uploading firmware file: $NexsanInfo->{firmwarefile}");
	
	#Tell the Nexsan to expect a firmware file
	say $sock "maint fwupload $NexsanInfo->{firmwarefile}";

	#check for the continue prompt
	$answer = <$sock>;
	unless ( $answer =~ /^1\d\d/ )#check for '100 Continue'
	{
		croak "Nexsan rejected 'maint fwupload' with: $answer\n";
	}
	WriteLog($NexsanInfo, $answer);
	
	
	#set binmode just to be sure? 
	
	#upload the file
	say $sock $firmwareData;
	#print $sock "\r\n";
	sleep(1); #give it a chance to complete - will hang waiting for the completion otherwise
	print $sock ".\r\n"; #send the last line to tell the nexsan the file has finished uploading
	#print $sock "\n";
	#say $sock ".";
	$answer = <$sock>;
	unless ( $answer =~ /^2\d\d/ ) 
	{
		croak "Nexsan firmware upload failed because: $answer\n";
	}
	WriteLog($NexsanInfo, $answer);
	WriteLog($NexsanInfo, "completed uploading firmware");

	my @answer;
	my $line;
	
	WriteLog($NexsanInfo, "checking firmware install status");
	say $sock "MAINT FWSTATUS";
	$answer = <$sock>;
	WriteLog($NexsanInfo, $answer);
	
	#prep the while loop and keep checking for the completion code
	#what we're looking for:
	#
	#Firmware update in progress (40%)
	#222 Microcode Updated OK
	#.
	
	sleep(1);
	#$line = <$sock>;
	say $sock "MAINT FWSTATUS";

	while ($line = <$sock>) 
	{
		#push @answer, $line;
		#say "checking firmware install status";
		say $sock "MAINT FWSTATUS";
		WriteLog($NexsanInfo, $line);
		#only get the lines we want, as while loop never exits otherwise
		 if ($line =~ /^222/)
		{
			WriteLog($NexsanInfo, "Nexsan firmware upload successfull!");
			last;
		}
		sleep(4);
		
	}

	#TODO write send command subroutine that cheks for conection having gone away
	#TODO put log in of IP and date/time on any say command - subroutine?

	
	#reset the status of the firmware upload for the GUI and other users
	WriteLog($NexsanInfo, "Resetting status of last firmware update to return GUI to normal state");
	say $sock "MAINT FWRESETSTATUS";
	$answer = <$sock>;
		unless ( $answer =~ /^2\d\d/ )
	{
		croak "Nexsan firmware status reset failed because: $answer\n";
	}
	WriteLog($NexsanInfo, $answer);
	

	
} #end of sub UploadFirmwareToNexsan	

=head2 ShutdownNexsan

To quote the NMP Reference Manual (v.2.3.0);
"This command will perform a shutdown of the RAID system , the NMP connection will be closed. 
All cached data will be flushed to the disks, it is advised all host IO is stopped before 
this command is used. There are circumstances where shutdown is blocked (such as during a 
firmware update), these scenarios can be detected from the returned response."


=cut

sub ShutdownNexsan {

	#assign the variables, and set defaults if not passed
	my ($NexsanInfo) = shift;
	my $sock; #can't use the hash version with say for some reason

	if (!exists $NexsanInfo->{sock})
	{
		croak "socket not passed to Storage::Nexsan::NMP::Authenticate()\n";
	}	
	else
	{
		$sock = $NexsanInfo->{sock};
	}
	#also check we've successfully authenticated, as this will only be populated if we did
	if (!exists $NexsanInfo->{password})
	{
		croak "password not passed to Storage::Nexsan::NMP::Authenticate() - not authenticated?\n";
	}	

	say $sock "MAINT SHUTDOWN";
	my $answer = <$sock>;
	
	if ( $answer =~ /^2\d\d/ )
    {
	
		WriteLog($NexsanInfo, $answer);
		return 0;
	}
	else
	{
		
		#$answer =~ /^(\d+)\s/;
		carp "Error - failed to shutdown with response: $answer\n";
	}


} #end of ShutdownNexsan()

=head2 RollingRebootNexsan

To quote the NMP Reference Manual (v.2.3.0);
"This command will perform a rolling restart of the RAID system , the NMP connection will be 
 closed. Each controller is restarted in turn and therefore should minimize the amount time 
 the storage is inaccessible. There are circumstances where rolling restart is blocked (such 
 as during a firmware update), these scenarios can be detected from the returned response."


=cut

sub RollingRebootNexsan {

	#assign the variables, and set defaults if not passed
	my ($NexsanInfo) = shift;
	my $sock; #can't use the hash version with say for some reason

	if (!exists $NexsanInfo->{sock})
	{
		croak "socket not passed to Storage::Nexsan::NMP::Authenticate()\n";
	}	
	else
	{
		$sock = $NexsanInfo->{sock};
	}
	#also check we've successfully authenticated, as this will only be populated if we did
	if (!exists $NexsanInfo->{password})
	{
		croak "password not passed to Storage::Nexsan::NMP::Authenticate() - not authenticated?\n";
	}	

	say $sock "MAINT ROLLING";
	my $answer = <$sock>;
	
	if ( $answer =~ /^2\d\d/ )
    {
	
		WriteLog($NexsanInfo, $answer);
		return 0;
	}
	else
	{
		
		#$answer =~ /^(\d+)\s/;
		carp "Error - failed to initiate a rolling reboot with response: $answer\n";
	}


}#end of RollingRebootNexsan()
	
=head2 TurnOffMAIDOnNexsan

	#MUST be passed a reference to a hash containing socket
	
	This uses the SETOPT command to add the following MAID entry, as if it were uploaded 
	via a settings.dat file;
	
	[PowerConfig]
	PowerLevel1 = 2 ; 0, 2, 5 minutes
	PowerLevel2 = 0 ; 0, 10, 20, 30, 40, 50, 60 minutes
	PowerLevel3 = 0 ; 0, 15, 30, 60, 90, 120 minutes
	MaxSpareLevel = 2 ; 0, 1, 2, 3

	ASSUMPTION: that PowerLevel4 is not configured..

=cut

sub TurnOffMAIDOnNexsan {

	#assign the variables, and set defaults if not passed
	my ($NexsanInfo) = shift;
	my $sock; #can't use the hash version with say for some reason

	if (!exists $NexsanInfo->{sock})
	{
		croak "socket not passed to Storage::Nexsan::NMP::Authenticate()\n";
	}	
	else
	{
		$sock = $NexsanInfo->{sock};
	}
	#also check we've successfully authenticated, as this will only be populated 
	# if we did
	if (!exists $NexsanInfo->{password})
	{
		croak "password not passed to Storage::Nexsan::NMP::Authenticate() - not authenticated?\n";
	}	

	# I really should turn this into a script with an array or something, 
	#  but coding to a deadline..

	#NOTE Nexsan's require the Power levels to be set from most disruptive to least
	say $sock "SETOPT PowerConfig PowerLevel3 0";  #0, 15, 30, 60, 90, 120 minutes
	my $answer = <$sock>;
	
	if ( $answer =~ /^2\d\d/ )
    {


		WriteLog($NexsanInfo, $answer);
		#return 0;
	}
	else
	{
		
		carp "Error setting option with: $answer\n";
	}

	say $sock "SETOPT PowerConfig PowerLevel2 0"; # 0, 10, 20, 30, 40, 50, 60 minutes
	$answer = <$sock>;
	
	if ( $answer =~ /^2\d\d/ )
    {


		WriteLog($NexsanInfo, $answer);
		#return 0;
		#say $sock "GETOPT PowerConfig PowerLevel2";
		#$answer = <$sock>;
		#WriteLog($NexsanInfo, $answer);
	}
	else
	{
		
		carp "Error setting option with: $answer\n";
	}
	
	say $sock "SETOPT PowerConfig PowerLevel1 2"; # 0, 2, 5 minutes
	$answer = <$sock>;
	
	if ( $answer =~ /^2\d\d/ )
    {


		WriteLog($NexsanInfo, $answer);
		#return 0;
	}
	else
	{
		
		carp "Error setting option with: $answer\n";
	}
	
		say $sock "SETOPT PowerConfig MaxSpareLevel 2"; #0, 1, 2, 3
	$answer = <$sock>;
	
	if ( $answer =~ /^2\d\d/ )
    {


		WriteLog($NexsanInfo, $answer);
		#return 0;
	}
	else
	{
		
		carp "Error setting option with: $answer\n";
	}
	
	WriteLog($NexsanInfo, "MAID Disabled at levels 2 and 3, minimised at level 1");
	return 0;

} #end of sub TurnOffMAIDOnNexsan

=head2 importDatFile

Import an .ini file (called .dat by Nexsan) that provides many confuguration options.
The idea is that it can be used by another function to then upload a atandard config, 
replicating the behaviour of the GUI.

Requires a filename scalar passed to it, and returns a hash reference, for e.g.;

$HASH1 = {
           ActiveActive
                    => { ActiveActiveMode => 'APAL' },
           Cache    => {
                         AllowSCSIOverride
                                       => 'Disabled',
                         Cache         => 'Enabled',
                         CacheTuning   => 'Mixed',
                         IgnoreForceUnitAccess
                                       => 'Enabled',
                         Mirroring     => 'Enabled',
                         ReadStreamMode
                                       => 'Disabled',
                         StreamingMode => 'Disabled'
                       },
           SYSLOG   => {
                         Facility   => 'LOCAL0',
                         SendToIP   => '172.17.9.9',
                         UDPPort    => 514,
                         WhenToSend => 'All'
                       }
         };

=cut

sub importDatFile {
	my $ConfigFileName = shift || croak "no filename provided to import";
	my $hash = Config::INI::Reader->read_file($ConfigFileName) 
		|| croak "error reading file because: $!\n";
	
	return $hash;

}	#end of sub importDatFile
	
	
=head2 SetOpt

using the importDatFile internal function, apply a number of Nexsan Dat file stanza's.

The sub expects $NexsanInfo->{datfile} populated with the name of the dat file to import.

Note: no error checking is done on the hash to see it contains a correct INI structure
 as it assumes that its been imported from an Nexsan created/modified DAT file.
 Given the SETOPT command if not passed the write information, this is relatively low risk
 
 TODO apply some error checking for correct INI structure, as above!
 TODO write a specific subroutine for the Powerlevel stanza 
 	(see notes in TurnOffMAIDInNexsan)

=cut

sub SetOpt {
	
	#assign the variables, and set defaults if not passed
	my ($NexsanInfo) = shift;
	my $sock; #can't use the hash version with say for some reason

	if (!exists $NexsanInfo->{sock})
	{
		croak "socket not passed to Storage::Nexsan::NMP::Authenticate()\n";
	}	
	else
	{
		$sock = $NexsanInfo->{sock};
	}
	#also check we've successfully authenticated, as this will only be populated 
	# if we did
	if (!exists $NexsanInfo->{password})
	{
		croak "password not passed to Storage::Nexsan::NMP::Authenticate() - not authenticated?\n";
	}	
	
	#get the file to import
	if (!exists $NexsanInfo->{datfile})
	{
		croak "dat filename not passed to Storage::Nexsan::NMP::SetOpt ?\n";
	}
	
	#load the dat file into a hash
	my $hash_ref = importDatFile($NexsanInfo->{datfile});
	
	my ($key, $value);
	while ( ($key, $value) = each %$hash_ref ) #get list of stanzas
	{
		if ( ref($value) ) #check the stanza entry has a value
		{ 			#get hash's for each stanza		
			my ($element, $element_value);
			while ( ($element, $element_value) = each %$value ) #get individual values
			{
				say $sock "SETOPT $key $element $element_value";
				my $answer = <$sock>;
	
				if ( $answer =~ /^2\d\d/ )
    			{
					WriteLog($NexsanInfo, $answer);
				}
				else
				{
					carp "Error setting option with: $answer\n";
				}
			}
		}
		#here for individual lines, which there shouldn't be
		else { carp " dat file contains standalone lines: $key => $value"; } 
	}
	
} #end of sub SetOpt	
	
#=head2 function2
#
#=cut
#
#sub function2 {
#}

=head1 AUTHOR

John Constable, C<< <john.constable at sanger.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-storage-nexsan-nmp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Storage-Nexsan-NMP>.  I will 
be notified, and then you'll automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Storage::Nexsan::NMP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Storage-Nexsan-NMP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Storage-Nexsan-NMP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Storage-Nexsan-NMP>

=item * Search CPAN

L<http://search.cpan.org/dist/Storage-Nexsan-NMP/>

=back


=head1 ACKNOWLEDGEMENTS

James Peck at Nexsan dot com for helping approve the release of this and answering inumerable questions
Carl Elkins at sanger dot ac dot uk for allowing me the time to write this


=head1 LICENSE AND COPYRIGHT

Copyright 2011 John Constable.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Storage::Nexsan::NMP
