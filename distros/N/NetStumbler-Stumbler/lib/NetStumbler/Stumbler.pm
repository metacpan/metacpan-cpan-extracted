package NetStumbler::Stumbler;

use strict;
use warnings;
use Carp qw(cluck carp croak);

require NetStumbler::Wap;
require Exporter;

our @ISA = qw(Exporter);

#
# We do not Export anything
#

our $VERSION = '0.07';
our $wapinfo = NetStumbler::Wap->new();

=head1 Object Methods

=head2 new()

Returns a new Stumbler object.

=cut

sub new
{

	my $proto = shift;
	my $class = ref($proto) || $proto;
    	my $self  = {};
    	bless ($self, $class);
    	$wapinfo->initialize();
    	return $self;
}


=head2 parseNSSummaryLine($line)

Params:
	-string A line from a summary file
Returns:
	an array of seperated values corresponding to output of a NetStumbler summary export
	**NOTE**
		<li>Conversion of the verbose GPS data to doubles in standard GPS format</li>
		<li>Blank SSID will be set to "Hidden"</li>
		<li>The time data will have GMT stripped off</li>
		<li>If the line is not correctly formed return an empty list</li>
Example:
	my @line = $obj->parseNSSummaryLine($line);
	print "Line [@line]\n";

=cut


sub parseNSSummaryLine
{
	my $self = shift;
	my $line = shift;
	my($d1,$lat,$d2,$lon,$ssid,$type,$mac,$time,$snr,$sig,$noise,$name,$flags,$chanbits,$bcninterval,$datarate,$lastchannel);
	my ($nlat,$nlon);
	if($line =~ /^#/)
	{
		return [];
	}
	if($line =~ /(\w).(\d+\.\d+)\t(\w).(\d+\.\d+)\t\(.(.*).\)\t(\S+)\t\(.(\w+\:\w+\:\w+\:\w+\:\w+\:\w+).\)\t(.*)\[.(\w+).(\w+).(\w+).\]\t\#.\((.*)\)\t(\d+)\t(\d+)\t(\d+)\t(\d+)\t(\d+)/)
	{
		$d1 = $1;
		$lat = $2;
		$d2 = $3;
		$lon = $4;
		$ssid = $5;
		$type = $6;
		$mac = $7;
		$time = $8;
		if($time)
		{
			$time =~ s/\(GMT\)//;
		}
		chomp($time);
		if($mac)
		{
			$mac =~ s/\://g;
		}
		$snr = $9;
		$sig = $10;
		$noise = $11;
		$name = $12;
		unless($name) { $name = "";};
		$flags = hex($13);
		$chanbits = hex($14);
		$bcninterval = $15;
		unless($16) { $datarate = $16/10; };
		$lastchannel = $17;
		if(!$ssid){ $ssid = "Hidden";}
		if(!$lat){ $lat = 0.00; }
		if(!$lon){ $lon = 0.00; }
		if(!$d1){ $d1 = "N";}
		if(!$d2){ $d2 = "W";}
		if($d1 =~ /[sS]/){$lat = "-$lat";}
		if($d2 =~ /[wW]/){$lon = "-$lon";}
		return ($lat,$lon,$ssid,$type,$mac,$time,$snr,$sig,$noise,$flags,$chanbits,$datarate,$lastchannel);
	}
	else
	{
		return [];
	}
}

=head2 isSummary($file)

Params:
	-string fully qualified filename
Returns:
	true if the file is in NetStumbler Summary format
Example:
	if($obj->isSummary($file))
	{
		# do something here
	}

=cut

sub isSummary
{
	my $self = shift;
    	my $file = shift;
    	open(FD,$file) or cluck "Failed to open input file $!\n";
    	my $found = 0;
    	while(<FD>)
    	{
    	    if(/^#/)
    	    {
    	        if(/wi-scan summary with extensions/)
    	        {
    	            $found = 1;
    	        }
    	    }
    	    if($found)
    	    {
    	        last;
    	    }
    	}
    	close(FD);
    	return $found;
}

=head2 isNS1($file)

Params:
	-string fully qualified filename
Returns:
	true if the file is in NetStumbler NS1 file
Example:
	if($obj->isNS1($file))
	{
		# do something here
	}

=cut

sub isNS1
{
	my $self = shift;
    	my $file = shift;
    	open(FD,$file) or cluck "Failed to open input file $!\n";
    	my $magic;
    	binmode(FD);
    	read(FD,$magic,4);
    	if($magic eq 'NetS') { return 1; }
    	else { return 0; }
}

=head2 isKismetCSV($file)

Params:
	-string fully qualified filename
Returns:
	true if the file is in Kismet CSV file
Example:
	if($obj->isKismetCSV($file))
	{
		# do something here
	}

=cut

sub isKismetCSV
{
	my $self = shift;
    	my $file = shift;
    	open(FD,$file) or cluck "Failed to open input file $!\n";
    	my $magic;
    	binmode(FD);
    	read(FD,$magic,7);
    	if($magic eq 'Network') { return 1; }
    	else { return 0; }	
}

=head2 parseKismetCSV($file)

Params:
	-string fully qualified filename
Returns:
	list of lists each item in the sublist corresponds to a list from kismet summary file
Example:
	$ref = $obj->parseKismetCSV($file);
	# The list is as follows
	0  Network
	1  NetType
	2  ESSID
	3  BSSID
	4  Info
	5  Channel
	6  Cloaked
	7  WEP
	8  Decrypted
	9  MaxRate
	10 MaxSeenRate
	11 Beacon
	12 LLC
	13 Data
	14 Crypt
	15 Weak
	16 Total
	17 Carrier
	18 Encoding
	19 FirstTime
	20 LastTime
	21 BestQuality
	22 BestSignal
	23 BestNoise
	24 GPSMinLat 
	25 GPSMinLon
	26 GPSMinAlt
	27 GPSMinSpd
	28 GPSMaxLat
	29 GPSMaxLon
	30 GPSMaxAlt
	31 GPSMaxSpd
	32 GPSBestLat
	33 GPSBestLon
	34 GPSBestAlt
	35 DataSize
	36 IPType
	37 IP
	#

=cut

sub parseKismetCSV
{
	my $self = shift;
	my $file = shift;
	my $fh;
	open(FH,$file);
	$fh = \*FH;
	my $line;
	<$fh>;
	$line = <$fh>;
	my @list;
	while(<$fh>)
	{
		$line = $_;
		push(@list,[split(/;/,$line)]);
	}
	return @list;
}

=head2 parseNS1($file)

Params:
	-string fully qualified filename
Returns:
	list of lists each item in the sublist corresponds to a list from parseNSSummary
Example:
	$ref = $obj->parseNS1($file);

=cut

sub parseNS1
{
	my $self = shift;
	my $file = shift;
	my $fh;
	open(FH,$file);
	$fh = \*FH;
	my ($sig,$ver,$apCount);
	my $line;
	read($fh,$line,12);
	($sig,$ver,$apCount) = unpack("A4LL",$line);
	unless($sig =~ /NetS/) { return []; }
	unless($ver > 6) { carp "Version $ver not supported!\n"; return []; }
	my @list;
	for(my $i=0;$i<$apCount;$i++)
	{
		push(@list, [ readAPInfo($fh,$ver) ]);
	}
	return @list;
}

=head1 Private Methods

=head2 readAPInfo($fileHandle,$fileVersion)

Params:
	reference - Filehandle reference
	number	- NS1 Version
Returns:
	list - smae format as parseNSSummary

=cut


sub readAPInfo
{
    my @apData;    
    my $fh = shift;
    my $ver = shift;
    my $sl = readUint8($fh);
    my $sid = readChars($fh,$sl);
    my $mac;
    my @ml;
    for(my $ms=0;$ms<6;$ms++)
    {
        push(@ml,readUint8($fh));
    }
    $mac = sprintf("%02x:%02x:%02x:%02x:%02x:%02x",@ml);
    my($mSig,$mNoi,$mSnr,$flags,$beacon,$fs,$ls,$blat,$blon,$dCount);
    $mSig = readint32($fh);
    $mNoi = readint32($fh);
    $mSnr = readint32($fh);
    $flags = readUint32($fh);
    $beacon = readUint32($fh);
    $fs = readint64($fh);
    $ls = readint64($fh);
    $blat = readDouble($fh);
    $blon = readDouble($fh);
    $dCount = readUint32($fh);
    push(@apData,$blat);
    push(@apData,$blon);
    push(@apData,$sid);
    if($wapinfo->isInfrastructure($flags))
    {
	push(@apData,"BSS");
    }
    else
    {
	push(@apData,"Ad-Hoc");
    }
    push(@apData,$mac);
    push(@apData,$fs);
    push(@apData,$mSnr);
    push(@apData,$mSig);
    push(@apData,$mNoi);
    
    for(my $xl=0;$xl<$dCount;$xl++)
    {
        my $rc = readAPData($fh,$ver);
    }    
    my $nl = readUint8($fh);
    my $name = readChars($fh,$nl);
    push(@apData,$flags);
    push(@apData,$name);
    if($ver > 6)
    {
        my ($channels,$lchan,$ip,$min,$maxNoise,$dr,$ipsub,$ipmask,$pflags,$ieLength);
        $channels = readint64($fh);
        $lchan = readUint32($fh);
        $ip  = readUint8($fh);
        $ip .= "." . readUint8($fh);
        $ip .= "." . readUint8($fh);
        $ip .= "." . readUint8($fh);
        $min = readint32($fh);
        $maxNoise = readint32($fh);
        $dr = readUint32($fh);
        $ipsub = readUint8($fh);
        $ipsub .= "." . readUint8($fh);
        $ipsub .= "." . readUint8($fh);
        $ipsub .= "." . readUint8($fh);
        push(@apData,$channels);
        push(@apData,$beacon);
        push(@apData,$dr);
        push(@apData,$lchan);
        if($ver > 8)
        {
            $ipmask = readUint8($fh);
            $ipmask .= "." . readUint8($fh);
            $ipmask .= "." . readUint8($fh);
            $ipmask .= "." . readUint8($fh);
        }
        if($ver > 11)
        {
            $pflags = readUint32($fh);
            $ieLength = readUint32($fh);
            if($ieLength > 0)
            {
                for(my $iel=0;$iel < $ieLength;$iel++)
                {
                    readUint8($fh);
                }
            }
        }
    }
    return @apData;
}

=head2 readAPData($fileHandle,$fileVersion)

Params:
	reference - Filehandle reference
	number	- NS1 Version
Returns:
	nothing 
	TODO:
		Add a return value to this method to build graphs

=cut

sub readAPData
{
    my $fh = shift;
    my $ver = shift;
    my ($time,$sig,$noise,$loc);
    $time = readint64($fh);
    $sig = readint32($fh);
    $noise = readint32($fh);
    $loc = readint32($fh);
    if($loc > 0)
    {
        readGPSData($fh);
    }
}

=head2 readGPSData($fileHandle)

Params:
	reference - Filehandle reference
Returns:
	nothing 
	TODO:
		Add a return value to this method to build graphs

=cut

sub readGPSData
{
    my $fh = shift;
    my ($lat,$lon,$alt,$numSat,$speed,$track,$magVar,$hdop);
    $lat = readDouble($fh);
    $lon = readDouble($fh);
    $alt = readDouble($fh);
    $numSat = readUint32($fh);
    $speed = readDouble($fh);
    $track = readDouble($fh);
    $magVar = readDouble($fh);
    $hdop = readDouble($fh);
}

=head2 readint64($fileHandle)

Params:
	reference - Filehandle reference
Returns:
	a 64bit number

=cut

sub readint64
{
    my $fh = shift;
    #my $l;
    #my ($p,$t);
    #$p = tell($fh);
    #my $r = read($fh,$l,8);
    #$t = tell($fh);
    #ensurePos($fh,$p,$t,8);
    #if($r != 8){die "Failed to read int64 $r $!\n";}
    #return unpack("L2",$l);        
    return (readint32($fh) << 32) + readint32($fh);
}

=head2 readDouble($fileHandle)

Params:
	reference - Filehandle reference
Returns:
	a double

=cut

sub readDouble
{
    my $fh = shift;
    my $l;
    my ($p,$t);
    $p = tell($fh);
    my $r = read($fh,$l,8);
    $t = tell($fh);
    ensurePos($fh,$p,$t,8);
    if($r != 8){die "Failed to read double $r $!\n";}
    return unpack("d",$l);        
}

=head2 readint32($fileHandle)

Params:
	reference - Filehandle reference
Returns:
	a 32bit number

=cut

sub readint32
{
    my $fh = shift;
    my $l;
    my ($p,$t);
    $p = tell($fh);
    my $r = read($fh,$l,4);
    $t = tell($fh);
    ensurePos($fh,$p,$t,4);
    if($r != 4){die "Failed to read int32 $r $!\n";}
    return unpack("l",$l);    
}

=head2 readUint32($fileHandle)

Params:
	reference - Filehandle reference
Returns:
	an unsigned 32bit number

=cut

sub readUint32
{
    my $fh = shift;
    my $l;
    my ($p,$t);
    $p = tell($fh);
    my $r = read($fh,$l,4);
    $t = tell($fh);
    ensurePos($fh,$p,$t,4);
    if($r != 4){die "Failed to read Uint32 $r $!\n";}
    return unpack("L",$l);
}

=head2 readUint8($fileHandle)

Params:
	reference - Filehandle reference
Returns:
	an unsigned 8bit number

=cut

sub readUint8
{
    my $fh = shift;
    my $l;
    my ($p,$t);
    $p = tell($fh);
    my $r = read($fh,$l,1);
    $t = tell($fh);
    ensurePos($fh,$p,$t,1);
    if($r != 1){die "Failed to read Uint8 $r $!\n";}
    return unpack("C",$l);
}

=head2 readChars($fileHandle,$length)

Params:
	reference - Filehandle reference
	length - number of bytes to read
Returns:
	a string

=cut

sub readChars
{
    my $fh = shift;
    my $length = shift;
    my $l;
    my ($p,$t);
    $p = tell($fh);
    my $r = read($fh,$l,$length);
    $t = tell($fh);
    ensurePos($fh,$p,$t,$length);
    if($r != $length) { die "Failed to read $length ($r) $!\n";}
    return unpack("A*",$l);
}

=head2 ensurePos($fileHandle,$prePosition,$postPosition,$amountNeeded)

This method was aadded due to an odd behavior with Perl5.8 read would sometimes
put the file pointer 1 byte beyond where it was supposed to be. This method fixes that issue
Params:
	reference - Filehandle reference
	number	  - Pre read position of the file
	number    - Post position of the file
	number	  - Correct amount to data that was supposed to be read

=cut

sub ensurePos
{
    my ($fh,$prePos,$postPos,$amt) = @_;
    my $diff = ($postPos-$prePos);
    if($diff != $amt)
    {
        $diff -= $amt;
        $postPos -= $diff;
        seek($fh,$postPos,0);
    }
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

NetStumbler::Stumbler - Module to parse netstumbler data

=head1 SYNOPSIS

  use NetStumbler::Stumbler;
  my $lin = NetStumbler::Stumbler->new();
  $lin->isSummary($file);
  $lin->isNS1($file);
  $lin->parseNS1($file);
  
=head1 DESCRIPTION

This class has several methods to parse NetStumbler data file
TODO: add Kismet and iStumbler support

=head2 EXPORT

None by default.


=head1 SEE ALSO

http://www.netstumbler.org Net Stumbler
http://stumbler.net/ns1files.html NS1 Information

=head1 AUTHOR

Salvatore E. ScottoDiLuzio<lt>washu@olypmus.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Salvatore ScottoDiLuzio

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
