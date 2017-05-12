package RADIUS::XMLParser;

use strict;
use warnings;

use File::Basename;
use File::Spec;
use Storable qw(lock_store lock_retrieve);
use Carp;
use IO::File;
use XML::Writer;

our $VERSION = '2.30';

my $interimUpdate;
my $writer;
my $labelref;
my $mapRef;
my $startDbm;
my $interimDbm;
my $daysForOrphan  = 1;
my $purgeOrphan    = 0;
my $writeAllEvents = 0;
my $outputDir;
my $orphanDir;
my $xmlencoding = "utf-8";

my %map;
my @labels;
my %tags = ();
my %event;
my %start;
my %stop;
my %interim;

#--------------------------------------------------
# Constructor
#--------------------------------------------------
sub new {

	my $this   = shift;
	my $class  = ref($this) || $this;
	my $ref    = shift;
	my %params = %$ref;

	#Load parameters if any
	$mapRef         = $params{MAP}           if $params{MAP};
	$purgeOrphan    = $params{AUTOPURGE}     if $params{AUTOPURGE};
	$daysForOrphan  = $params{DAYSFORORPHAN} if $params{DAYSFORORPHAN};
	$writeAllEvents = $params{ALLEVENTS}     if $params{ALLEVENTS};
	$xmlencoding    = $params{XMLENCODING}   if $params{XMLENCODING};
	$outputDir      = $params{OUTPUTDIR}     if $params{OUTPUTDIR};
	$orphanDir      = $params{ORPHANDIR}     if $params{ORPHANDIR};
	%map            = %$mapRef               if $mapRef;

	#Get current directory
	my $curdir = File::Spec->tmpdir();
	$outputDir = $curdir if ( not defined $outputDir );
	$orphanDir = $curdir if ( not defined $orphanDir );

	#Get orphan files
	$startDbm   = File::Spec->catfile( $orphanDir, "orphan.start" );
	$interimDbm = File::Spec->catfile( $orphanDir, "orphan.interim" );

	my $self = {};
	bless $self => $class;

	#Load orphan start and interim hash (if any)
	_loadHash();

	$self;
}

#--------------------------------------------------
# Clean up orphanage on demand
# Note that this is done at startup, but might
# be required some times to times
# (especially for deamons process)
#--------------------------------------------------
sub flush($) {
	my ($self) = @_;
	_loadHash();
}

#--------------------------------------------------
# Open log file and parse each line.
# Group then all event based on same session ID
#--------------------------------------------------
sub convert($$) {

	my ( $self, $log ) = @_;

	#Initialize counters
	my $processedLines = 0;

	#Open log file to be parsed
	croak "Log file not supplied" if ( not defined $log );

	#Get absolute path
	$log = File::Spec->rel2abs($log);

	open( LOG, $log ) or croak "Cannot open file; File=$log; $!";

	#Boolean that becomes true (1) when the first blank lines have been skipped.
	my $begining_skipped = 0;

	#Get each line
	while (<LOG>) {

		$processedLines++;

		# Skip the begining of the log file if it only contains blank lines.
		if ( /^(\s)*$/ && !$begining_skipped ) {
			next;
		} else {
			$begining_skipped = 1;
		}

		# Analyze line
		_analyseRadiusLine( $_, $processedLines, $log );
	}

	#Store file into XML
	my $xmlReturnRef = _event2xml($log);
	my %xmlReturn    = %$xmlReturnRef;

	#Log has been parsed
	close(LOG);

	#Reinitializing Stop hash table but keep Start and Interim as orphans
	%stop = ();

	return ( $xmlReturn{XML_FILE}, $xmlReturn{XML_STOP}, $xmlReturn{XML_START}, $xmlReturn{XML_INTERIM}, $processedLines );

}

#--------------------------------------------------
# Convert Stop event hash reference to XML
#--------------------------------------------------
sub _event2xml($) {

	my ($log) = shift;

	#Initialize counter
	my $stopevents    = 0;
	my $startevents   = 0;
	my $interimevents = 0;

	#Create output xml file
	my $xml = basename($log);

	#Replace extension
	$xml =~ s/\.[^.]+$//;
	$xml .= ".xml";

	#Create path
	$xml = File::Spec->catfile( $outputDir, $xml );

	#Create a new IO::File
	my $output = IO::File->new(">$xml")
	  or croak "Cannot open file $xml, $!";

	#Load XML:Writer
	$writer = XML::Writer->new(
		OUTPUT      => $output,
		ENCODING    => $xmlencoding,
		DATA_MODE   => 1,
		DATA_INDENT => 1
	) or croak "cannot create XML::Writer: $!";

	#Start writing
	$writer->xmlDecl( uc($xmlencoding) );

	#Write a new SESSIONS tag
	$writer->startTag("sessions");

	#For each provided Stop event
	foreach my $sessionId ( keys %stop ) {

		#Open SESSION tag
		$writer->startTag( "session", 'sessionId' => $sessionId );
		my $newRef = $stop{$sessionId};
		my %event  = %$newRef;
		$stopevents++;

		#Open START tag
		my %startevent = ();

		#And try to retrieve the respective Start session in orphan hash (based on unique session Id)
		my $starteventref = _findInStartQueue($sessionId);
		$writer->startTag("start");
		if ($starteventref) {
			$startevents++;

			#Write content
			_writeEvent($starteventref);
		}

		#Close START tag
		$writer->endTag("start");

		#Open INTERIMS tag
		my %interimevents = ();

		#And try to retrieve all the respective Interim sessions in orphan hash (based on unique session Id)
		my $interimeventsref = _findInInterimQueue($sessionId);
		$writer->startTag("interims");
		if ($interimeventsref) {
			%interimevents = %$interimeventsref;
			for my $event ( sort keys %interimevents ) {

				#Open INTERIM tag
				$writer->startTag( "interim", "id" => $event );
				$interimevents++;

				#Write content
				_writeEvent( $interimevents{$event} );

				#Close INTERIM tag
				$writer->endTag("interim");
			}
		}

		#Close INTERIMS tag
		$writer->endTag("interims");

		#Open STOP tag
		$writer->startTag("stop");

		#Write content
		_writeEvent( \%event );

		#Close STOP tab
		$writer->endTag("stop");

		#Close SESSION tag
		$writer->endTag("session");
	}

	#[OPTIONAL]
	#If User wants all events to be reported, let us process start event
	if ($writeAllEvents) {

		for my $sessionId ( keys %start ) {

			#Open a SESSION Tag
			$writer->startTag( "session", 'sessionId' => $sessionId );
			my $newRef = $start{$sessionId};

			#Open START tag
			$writer->startTag("start");
			_writeEvent($newRef);
			$startevents++;

			#Close START tag
			$writer->endTag("start");

			#Open INTERIMS tag
			my %interimevents = ();

			#And try to retrieve all the respective Interim sessions in orphan hash (based on unique session Id)
			my $interimeventsref = _findInInterimQueue($sessionId);
			$writer->startTag("interims");
			if ($interimeventsref) {
				%interimevents = %$interimeventsref;
				for my $event ( sort keys %interimevents ) {

					#Open INTERIM tag
					$writer->startTag( "interim", "id" => $event );
					$interimevents++;

					#Write content
					_writeEvent( $interimevents{$event} );

					#Close INTERIM tag
					$writer->endTag("interim");
				}
			}

			#Close INTERIMS tag
			$writer->endTag("interims");

			#Open STOP tag
			$writer->startTag("stop");

			#Do not write content as all the stop events have been already processed

			#Close STOP tab
			$writer->endTag("stop");

			#Close SESSION tag
			$writer->endTag("session");

			#And delete orphan record
			delete $start{$sessionId};

		}

		#If User wants all events to be reported, let us process interim event
		for my $sessionId ( keys %interim ) {

			#Open a SESSION Tag
			$writer->startTag( "session", 'sessionId' => $sessionId );
			my $newRef        = $interim{$sessionId};
			my %interimevents = %$newRef;

			#Open START tag
			$writer->startTag("start");

			#Do not write content as all the start events have been already processed
			#Close START tag
			$writer->endTag("start");

			for my $event ( sort keys %interimevents ) {

				#Open INTERIM tag
				$writer->startTag( "interim", "id" => $event );
				$interimevents++;

				#Write content
				_writeEvent( $interimevents{$event} );

				#Close INTERIM tag
				$writer->endTag("interim");
			}

			#Open STOP tag
			$writer->startTag("stop");

			#Do not write content as all the stop events have been already processed
			#Close STOP tab
			$writer->endTag("stop");

			#Close SESSION tag
			$writer->endTag("session");

			#And delete orphan record
			delete $interim{$sessionId};
		}
	}

	#Close SESSIONS tag
	$writer->endTag("sessions");
	$writer->end();
	$output->close();

	my %retunedhash = ();
	$retunedhash{XML_FILE}    = $xml;
	$retunedhash{XML_STOP}    = $stopevents;
	$retunedhash{XML_START}   = $startevents;
	$retunedhash{XML_INTERIM} = $interimevents;
	return \%retunedhash;
}

#--------------------------------------------------
# Remove oldest keys from hash
#--------------------------------------------------
sub _purgeStartOrphans($) {

	my $hashref = shift;
	my %hash    = %$hashref;
	my $removed = 0;

	#Current Epoch
	my $time = time;

	#Compute threshold in seconds
	my $threshold = $daysForOrphan * 24 * 3600;

	#Run through Start hash table
	foreach my $sessionId ( keys %hash ) {
		my $newHashRef = $hash{$sessionId};
		my %newHash    = %$newHashRef;

		if ( !$newHash{"Event-Timestamp"} ) {

			#Delete records without date
			delete $hash{$sessionId};
			$removed++;
			next;
		}

		#Compute max allowed delta time
		my $mtime = $newHash{"Event-Timestamp"};
		my $delta = $time - $mtime;
		if ( $delta > $threshold ) {

			#Delete oldest records
			delete $hash{$sessionId};
			$removed++;
			next;
		}
	}

	#Return reference of purged hash
	return \%hash;
}

#--------------------------------------------------
# Remove oldest keys from hash
#--------------------------------------------------
sub _purgeInterimOrphans($) {

	my $hashref = shift;
	my %hash    = %$hashref;
	my $removed = 0;

	#Current Epoch
	my $time = time;

	#Compute threshold in seconds
	my $threshold = $daysForOrphan * 24 * 3600;

	#Run through Interim hash tables
	foreach my $sessionId ( keys %hash ) {
		my $newHashRef = $hash{$sessionId};
		my %newHash    = %$newHashRef;
		foreach my $occurence ( keys %newHash ) {
			my $newNewHashRef = $newHash{$occurence};
			my %newNewHash    = %$newNewHashRef;
			if ( !$newNewHash{"Event-Timestamp"} ) {

				#Delete records without date
				delete $newHash{$occurence};
				$removed++;
				next;
			}

			#Compute max allowed delta time
			my $mtime = ( $newHash{"Event-Timestamp"} ) ? $newHash{"Event-Timestamp"} : 0;
			my $delta = $time - $mtime;
			if ( $delta > $threshold ) {

				#Delete oldest records
				delete $newHash{$occurence};
				$removed++;
				next;
			}
		}

		#Remove whole interims events if it does not get any interim session
		delete $hash{$sessionId} if ( !scalar( keys %newHash ) );
	}

	#Return reference of purged hash
	return \%hash;
}

#--------------------------------------------------
# Retrieve an orphan Start event based on sessionId
#--------------------------------------------------
sub _findInStartQueue($) {

	my ($sessionId) = @_;
	my $eventref = $start{$sessionId};
	if ( scalar( keys %$eventref ) ) {

		#found Start event
		#Remove start event from orphan hash
		delete $start{$sessionId};
	}

	#Return hash reference of found Start event, undef otherwise
	my $return = ( scalar( keys %$eventref ) ) ? $eventref : undef;
	return $return;

}

#--------------------------------------------------
# Retrieve an orphan interim event based on sessionId
#--------------------------------------------------
sub _findInInterimQueue($) {

	my ($sessionId) = @_;
	my $eventref = $interim{$sessionId};
	if ( scalar( keys %$eventref ) ) {

		#found Start event
		#Remove interim event from orphan hash
		delete $interim{$sessionId};
	}

	#Return hash reference of found Start event, undef otherwise
	my $return = ( scalar( keys %$eventref ) ) ? $eventref : undef;
	return $return;

}

#--------------------------------------------------
# Convert a set of key value from a given hash ref into XML
#--------------------------------------------------
sub _writeEvent($) {

	my $ref  = shift;
	my %hash = %$ref;

	#Check if labels have been supplied
	if ( !scalar( keys %map ) ) {

		#If not then add any label (tag) found earlier (during parsing)
		for my $key ( keys %tags ) {
			$map{$key} = $key;
		}
	}

	#convert only the supplied label
	for my $key ( keys %map ) {

		#Get this value
		my $value = $hash{$key};
		my $tag;
		if ( $map{$key} ) {
			$tag = $map{$key};
		} else {
			$tag = $key;
		}

		#Open a new TAG
		$writer->startTag($tag);
		$writer->characters($value) if $value;

		#Close TAG
		$writer->endTag($tag);

	}

}

#--------------------------------------------------
# Read stored hash if file exists
#--------------------------------------------------
sub _loadHash() {

	#Load previously stored hashes
	my $startref;
	my $interimref;

	#If file with stored hash exist - START
	if ( -e $startDbm ) {
		$startref = lock_retrieve($startDbm)
		  or croak "cannot open file $startDbm: $!";
		$startref = _purgeStartOrphans($startref) if $purgeOrphan;
		%start = %$startref;
	} else {

		#Does not exist, so initialize a new one
		%start = ();
	}

	#If file with stored hash exist - INTERIM
	if ( -e $interimDbm ) {
		$interimref = lock_retrieve($interimDbm)
		  or croak "cannot open file $interimDbm: $!";
		$interimref = _purgeInterimOrphans($interimref) if $purgeOrphan;
		%interim = %$interimref;
	} else {

		#Does not exist, so initialize a new one
		%interim = ();
	}

}

#--------------------------------------------------
# Retrieve the highest numeric key from a given hash
#--------------------------------------------------
sub _largestKeyFromHash ($) {

	my ($hash) = shift;
	my ( $key, @keys ) = keys %$hash;
	my ( $big, @vals ) = values %$hash;

	for ( 0 .. $#keys ) {
		if ( $vals[$_] > $big ) {
			$big = $vals[$_];
			$key = $keys[$_];
		}
	}

	#Return highest key value
	return $key;
}

#--------------------------------------------------
# Parse each line given as Input buffer
#--------------------------------------------------
sub _analyseRadiusLine($$$) {

	my ( $line, $lineNumber, $file ) = @_;

	if (   $line =~ /^[A-Za-z]{3}.*[A-Za-z]{3}/
		&& $line =~ /[0-9]{2}[:][0-9]{2}[:][0-9]{2}/ )
	{

		#Radius Date Format (1st line)
		#Should contain both MON and DAY (letter) And timestamp HH:MI:SS
		#Start of an event, initialize hash table

		%event = ();

	} elsif ( $line =~ m/^\n/ || $line =~ m/^[\t\s]+[\n]?$/ ) {

		#Empty line (end of session - Last line)

		my $val       = $event{"Acct-Status-Type"} || "";
		my $sessionId = $event{"Acct-Session-Id"}  || "";
		my $file      = basename($file);

		if ( $val =~ /.*[S,s]tart.*/ ) {

			#START event
			foreach my $key ( keys %event ) {

				#Store local start event to global Start events hash
				$start{$sessionId}{$key} = $event{$key};
			}

			$start{$sessionId}{File} = $file;

		} elsif ( $val =~ /.*[S,s]top.*/ ) {

			#STOP event
			foreach my $key ( keys %event ) {

				#Store local stop event to global Stop events hash
				$stop{$sessionId}{$key} = $event{$key};
			}

			$stop{$sessionId}{File} = $file;

		} elsif ( $val =~ /.*[I,i]nterim/ ) {

			#INTERIM event
			$interimUpdate = _largestKeyFromHash( $interim{$sessionId} );
			$interimUpdate++;
			foreach my $key ( keys %event ) {

				#Store local interim event to global Interims events hash
				$interim{$sessionId}{$interimUpdate}{$key} = $event{$key};
			}

			$interim{$sessionId}{$interimUpdate}{File} = $file;

		} else {

			#If EVENT is populated, this is a unmanaged EVENT or an unexpected empty line
			#Ignore it
			return;
		}

	} elsif ( my ( $tag, $val ) = ( $line =~ m/^\t([0-9A-Za-z:-]+)\s+=\s+["]?([A-Za-z0-9=\\\.-\_\s]*)["]?.*\n/ ) ) {

		#Between first and last line, we store any TAG/VALUE found

		if ($tag) {
			$tags{$tag}++;
			$event{$tag} = $val;
		}

	}

}

END {

	#Store computed Interim hash tables if not empty
	if ( scalar( keys %interim ) ) {
		lock_store \%interim, $interimDbm
		  or croak "Cannot store Interim to file $interimDbm: $!";
	}

	#Store computed Start hash tables if not empty
	if ( scalar( keys %start ) ) {
		lock_store \%start, $startDbm
		  or croak "Cannot store Start to file $startDbm: $!";
	}
}

#Keep Perl Happy
1;

=head1 NAME

RADIUS::XMLParser - Radius log file XML convertor


=head1 SYNOPSIS

=over 5

	use RADIUS::XMLParser;

	
	my %labels = (
		'Event-Timestamp' => 'Time', # name of tag "Event-Timestamp"
		'User-Name' => 'User', # name of tag "User-Name"
		'File' => '' # default name (i.e. File) for tag File
	);
	
	my $radius = RADIUS::XMLParser->new(
		{
			VERBOSE => 1,
			DAYSFORORPHAN => 1,
			AUTOPURGE => 0,
			ALLEVENTS => 1,
			OUTPUTDIR => '/tmp/',
			MAP => \%labels
		}
	);
	
	my ($xml, $stop, $start, $interim, $processed) = $radius->convert('radius.log');

=back

=head1 DESCRIPTION

=over

=item This module will extract and sort any radius events included into a radius log file. 

=item Note that your logfile must contain an empty line at its end otherwise the last event will not be analyzed.

=item Events will be grouped by their session ID and converted into XML sessions.

=item At this time, supported events are the following:


		START
		INTERIM-UPDATE
		STOP


=back

Any event will be stored on different hash (with SessionID as a unique key).
Then, for each STOP event, the respective START and INTERIM event will be retrieved (based on same session ID)

=over

=item [OPTIONAL] Each found START / INTERIM event will be written, final hash will be empty.

=item [OPTIONAL] Only the newest START / INTERIM events will be kept. Oldest ones will be considered as orphan events and will be dropped

=back

Final XML will get the following structure:


	<?xml version="1.0" encoding="UTF-8"?>
	<sessions>
	   <session sessionId=$sessionId>
	      <start></start>
	      <interims>
	         <interim id1></interim>
	      </interims>
	      <stop></stop>
	   </session>
	</sessions>


=head1 CONSTRUCTOR

=head2 Usage:

	my $parser = RADIUS::XMLParser->new({%params});

=head2 Return:

A radius parser blessed reference

=head2 Parameters:

Hash reference including below Options

=head2 Options:

=head3 [optional] VERBOSE

=over

=item Integer (0 by default) enabling verbose mode.

=item Regarding the amount of lines in a typical Radius log file (hundred MB large is the norm), verbose mode is split into several levels (0,1,2,3).

=back
	
=head3 [optional] MAP

=over

=item Hash reference of labels user would like to see converted into XML. 

=item Hash Keys are the keys to look for on Radius side

=item Hash Values are the name of the XML tags that will be written (XML keys are alias of Radius keys)

=item Empty values will result on tag's name = radius keys

=item Note that some Radius keys might not be XML compliant (e.g. <3GPP-XYZ-etc...>). This key / value approach will avoid such XML constraint

A reference to below Array passed as an input parameter...


	my %map = (
	  "Acct-Output-Packets"	=> "Output",
	  "NAS-IP-Address" => "Address",
	  "Event-Timestamp" => ""
	);


...will result on the following XML structure


	<stop>
		<Output></Output>
		<Address></Address>
		<Event-Timestamp></Event-Timestamp>
	</stop>

=item If MAP is not supplied, all the found Key / Values will be written. 

=item Else, only the supplied keys / values will be written	

=item  FYI, Gettings few MAP is significantly faster... Might save precious time when dealing with large files !

=back

=head3 [optional] AUTOPURGE

=over

=item Boolean (0 by default) that will purge stored hash reference (Start + Interim) before being used for Event lookup.

=item Newest events will be kept, oldest will be dropped.

=item Threshold is defined by below parameter DAYSFORORPHAN

=back

=head3 [optional] DAYSFORORPHAN

=over

=item Number of days user would like to keep the orphan Start + Interim events.

=item Default is 1 day; any event older than 1 day will be dropped.

=item AUTOPURGE must be set to true

=back

=head3 [optional] OUTPUTDIR

=over

=item Output directory where XML file will be created

=item Default is first temporary directory (returned by C<File::Spec->tmpdir()>)

=back
	
=head3 [optional] ALLEVENTS

=over

=item Boolean (0 by default).

=item If 1, all events will be written, including Start, Interim and Stop "orphan" records. 
Note that Orphan hash should be empty after processing.

=item If 0, only the events Stop will be written together with the respective Start / Interims for the same session ID. 
Note that Orphan hash should not be empty after processing, and therefore should be written on disk (under ORPHANDIR directory)

=back

=head3 [optional] XMLENCODING

=over

=item Only C<utf-8> and C<us-ascii> are supported 

=item default is C<utf-8>
		
=back

=head3 [optional] ORPHANDIR

=over

=item Default directory for orphan hash tables stored structure

=item Default is first temporary directory (returned by C<File::Spec->tmpdir()>)
		
=back

=head1 METHODS

=head2 convert

=head3 Description:

=over

=item The C<convert> will parse and convert provided file C<$radius_file>.

=item All its events will be retrieved, sorted and grouped by their unique sessionId.

=item Then, file will be converted into a XML format.

=back

=head3 Usage:
	
	my ($xml, $stop, $start, $interim, $processed) = $parser->convert($radius_file);
	
=head3 Parameter:
	
=over

=item C<$radius_file>: Radius log file that will be parsed. 
	
=back

=head3 Return:

=over

=item C<$xml>: The name of the XML file that has been created.

=item C<$stop>: The number of STOP event written

=item C<$start>: The number of START event written

=item C<$interim>: The number of INTERIM event written

=item C<$processed>: The number of processed lines in the original Radius log file

=back

=head2 flush

=head3 Description:

=over

=item The C<flush> method will cleanup orphanage on demand

=item Note that this process is already done at startup but might be required some times to times, especially for deamons processes which might never have to rebuild parser (C<new> method) 

=item Oldest orphans are dropped

=item Need PURGEORPHAN parameter set (optionnally DAYSFORORPHAN)

=back

=head3 Usage:

=over
	
	$parser->flush();
	
=back

=head1 EXAMPLE:


	use RADIUS::XMLParser;
	
	my $radius_file = 'radius.log';
	my %map = (
	  "NAS-User-Name" => "User-Name",
	  "Event-Timestamp"	=> "",
	  "File" => "File"
	);
	
	my $radius = RADIUS::XMLParser->new(
		{
			VERBOSE       => 1,
			DAYSFORORPHAN => 1,
			AUTOPURGE     => 0,
			ALLEVENTS     => 1,
			XMLENCODING   => "utf-8",
			OUTPUTDIR     => '/tmp/',
			MAP	          => \%map
		}
	);
	
	my ($xml, $stop, $start, $interim, $processed) = $radius->convert($radius_file);
	

Here is how the generated XML file will look like


	<?xml version="1.0" encoding="UTF-8"?>
	<session sessionId="d537cca0d43c95dc">
	  <start>
	   <Event-Timestamp>1334560899</Event-Timestamp>
	   <User-Name>User1</User-Name>
	   <File>radius.log</File>
	  </start>
	  <interims>
	   <interim id="1">
	    <Event-Timestamp>1334561024</Event-Timestamp>
	    <User-Name>User1</User-Name>
	    <File>radius.log</File>
	   </interim>
	   <interim id="2">
	    <Event-Timestamp>1334561087</Event-Timestamp>
	    <User-Name>User1</User-Name>
	    <File>radius.log</File>
	   </interim>
	  </interims>
	  <stop>
	   <Event-Timestamp>1334561314</Event-Timestamp>
	   <User-Name>User1</User-Name>
	   <File>radius.log</File>
	  </stop>
	 </session>


=head1 AUTHOR

Antoine Amend <amend.antoine@gmail.com>

=head1 MODIFICATION HISTORY

See the Changes file.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013 Antoine Amend. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

