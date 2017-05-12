#!/usr/local/new/bin/perl
use warnings;
use Getopt::Long;
use Compress::Zlib;
use Time::ParseDate;
use blib;
use Sort::Merge;

# Fix Time::Timezone to recognise MESZ/MEZ:
$Time::Timezone::dstZone{'mesz'} = +2*3600;
$Time::Timezone::Zone{'mez'} = +1*3600;
%Time::Timezone::zoneOff = reverse(%Time::Timezone::Zone);
%Time::Timezone::dstZoneOff = reverse(%Time::Timezone::dstZone);

#print %Time::Timezone::dstZone;

# get/parse options
# Get list of misagt.log.YYYYMMDD.hhmmss.gz files
# Open output file
# Open traprcvtime.log
# Read in until next \n\n
# Parse Date in first line of chunk
# Find matching misagt.log.YYYYMMDD.hhmmss.gz file
# Uncompress misagt.log
# Open misagt.log
# Loop through log, output 

my $traprcvlog     = 'traprcvtime.log';
my $outlog         = 'debugout.log';
my $mistraplog     = 'mistrap.log';
my $startdate      = undef;
my $enddate        = undef;
my $parsetext      = '.*' || 'Notification';
my $parsetraptext  = 'launched|shut down|failed';
GetOptions ('end=s' => \$enddate,
	    'traprcvlog:s' => \$traprcvlog,
	    'outputlog:s' => \$outlog,
	    'mistrap:s' => \$mistraplog,
	    'start=s' => \$startdate,
	    'parse:s' => \$parsetext);

my $start =  parsedate($startdate,
		       PREFERFUTURE => 1,
		       FUZZY => 1); 
my $end   =  parsedate($enddate,
		       PREFERFUTURE => 1,
		       FUZZY => 1); 
print "Got start, end: " . localtime($start) . ", " . localtime($end), "\n";
print "Got start, end: " . $start . ", " . $end, "\n";

my $saveterminator = $/;

open(OUTLOG,   ">$outlog")  || die "Can't open $outlog ($!)\n";

# Filtering !?

sub output {
    my $source=shift;
    $start ||= 0;
    $end ||= ~0;
    if($source->[1] >= $start && $source->[1] <= $end)
    {
	print OUTLOG $source->[2] if($source->[2]);
    }
}

Sort::Merge::sort_inner
  ([[\&getnextmistraplog],
      [\&getnextmisagtlog],
      [\&getnexttraplog] ],
      \&output);

close(OUTLOG);

$/ = $saveterminator;
print "Finished!";

{
    my $traphandle;

    sub getnexttraplog
    {
	local $/ = "\n\n";
	if(!defined($traphandle))
	{
	    open($traphandle,  $traprcvlog) || die "Can't open $traprcvlog ($!)\n";
	}

	my $chunk = <$traphandle>;
	close($traphandle), return unless ($chunk);

	my ($date) = $chunk =~ /(.*)/;
	my ($time, $rest) = parsedate($date,
				      PREFERFUTURE => 1,
				      FUZZY => 1);
	my $datetime = $time || 0;

#	print "Returning: $datetime, $chunk\n";

	return ($datetime, $chunk);
    }
}

{
    my $cthandle;

    sub getnextmistraplog
    {
	# Return line of log if it matches the date/time
	# Parameter: Date, Time
	local $/ = $saveterminator;

	if(!$cthandle)
	{
	    open($cthandle, "$mistraplog") || die "Can't open $mistraplog ($!)\n";
	}
	my $ctline = <$cthandle>;
	close($cthandle), return unless($ctline);

	if($ctline && $ctline =~ /^MISTRAP:\s+(.*)$/)
	{
	    $toparse = $1;
	    $toparse =~ s/MESZ/MEST/g;
	    my ($ctparsedate, $text) = parsedate($toparse, 
						 PREFERFUTURE => 1,
						 FUZZY => 1);
	    my $datetime = $ctparsedate || 0;
	    $ctline = "$toparse\n";

	    $ctline =~ /$parsetraptext/ or $ctline = '';

#	    print "Returning: $datetime, $ctline\n";
	    return ($datetime,$ctline);
	}
	return undef;
    }
}


{
    my @mislogfiles;
    my $logfileind;
    my $previouslog = '';
    my $currentlog = '';
    my $currentgzhandle = 0;
    my ($loglevel, $timestamp, $filename, $linenumber, $message);
    

    sub getnextmisagtlog
    {
	local $/ = "\n\n";
	# Return current log if it matches date/time, else find new log
	if(!@mislogfiles)
	{
	    @mislogfiles = sort {$a cmp $b } grep(/misagt\.log\.\d{8}\.\d{6}/, 
						  glob('misagt.log.*.*.gz'));
	    $logfileind = 0;
	}

	if($currentlog)
	{
#	    print "Misagtlog - return nextchunk\n";
	    return nextchunk() if($currentgzhandle);
	}
	else
	{
	    if($currentgzhandle)
	    {
		$currentgzhandle->gzclose();
		undef $currentgzhandle;
	    }
	}

#	print @mislogfiles;
	my $lfile = $mislogfiles[$logfileind++];

	return if(!$lfile);
	print "Got File: $lfile\n" if($lfile);
	
	my $ingz = gzopen($lfile, "rb");
	$currentgzhandle = $ingz;
	$previouslog = $currentlog;
	$currentlog = $lfile;

	return if($previouslog && $currentlog eq $previouslog);

	return nextchunk();
    }

    sub nextchunk
    {
	# Get next info from given gzhandle
	# Parameter: Gzhandle, Date, Time
	$ingz = $currentgzhandle;

	my ($gzline, $gzbytes) = ('', 0);
	$gzbytes = $ingz->gzreadline($loglevel);
	if(!$gzbytes && $gzerrno == Z_STREAM_END)
	{
	    $currentgzhandle->gzclose();
	    undef $currentgzhandle;
	    return getnextmisagtlog();
	}	    
	$ingz->gzreadline($timestamp);
	$ingz->gzreadline($filename);
	$ingz->gzreadline($linenumber);
	$ingz->gzreadline($message);
	$ingz->gzreadline($gzline);        # Read extra newline
	
	if($timestamp =~ /^Timestamp: \d+ \((.*)\)$/)
	{
	    $ldate = parsedate($1, 
			       PREFERFUTURE => 1,
			       FUZZY => 1);
	    my $datetime = $ldate || 0;
	    my $chunk = $loglevel.$timestamp.$filename.$linenumber.$message."\n";
#	    print "New CH: $chunk\n";
		
	    $message =~ /$parsetext/ or $chunk = '';
#	    print "Returning: $datetime, $chunk\n";
	    return ($datetime, $chunk);
	}

	return undef;
    }
}
