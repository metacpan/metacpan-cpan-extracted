#!/usr/bin/perl
# XMLScripted.pm
# Author: Singh T. Junior
# E-Mail: singhtjunior@gmail.com
# Date: 21 May 2006
# Chicago, IL


package Net::Download::XMLScripted::XMLScripted;

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use URI::Heuristic;
use 5.008006;

use strict;
use warnings;

require Exporter;

our $VERSION=0.10;

our @ISA = qw(Exporter AutoLoader);

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration  use Net::Download::XMLScripted::XMLScripted ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

package Net::Download::XMLScripted::XMLScriptedElement;
############################################################
## methods to access per-object data                      ##
############################################################
# initialize()
# Private Method
my $initialize_XMLScriptedElement = sub 
{
   my $self = shift;
   $self->{urlName} = "";
   $self->{fileName} = "";
   $self->{dirName} = "";
   $self->{fullFileName} = "";
   $self->{statusLog} = ();
   $self->{errorLog} = ();
};

############################################################
## the object constructor                                 ##
############################################################
sub new {
   my $invocant = shift;
   my $class = ref($invocant) || $invocant; # Object or class name
   my $self  = {@_};
   bless ($self, $class);
   $self->$initialize_XMLScriptedElement();
   return $self;	
}

############################################################
## methods to access per-object data                      ##
############################################################

# setUrlName()
sub setUrlName {
	my $self = shift;
	$self->{urlName} = shift;
}

# getUrlName()
sub getUrlName()
{
	my $self = shift;
	return $self->{urlName};
}

# setFileName()
sub setFileName() {
	my $self = shift;
	$self->{fileName} = shift;
}

# getFileName()
sub getFileName() {
	my $self = shift;
	return $self->{fileName};	
}

# setDirName()
sub setDirName() {
	my $self = shift;
	$self->{dirName} = shift;
}

# getDirName()
sub getDirName() {
    my $self = shift;
    return $self->{dirName};	
}

# setFullFileName()
sub setFullFileName()
{
	my $self = shift;
	$self->{fullFileName} = shift;
}

# getFullFileName()
sub getFullFileName()
{
	my $self = shift;
	return $self->{fullFileName};
}

# download()
sub download()
{
	my $self = shift;
	my $fullFileName = $self->getFullFileName();
	my $urlName = $self->getUrlName();
	#
	print ">>>Downloading ".$urlName." to ".$fullFileName."\n";
	#
	if ( -e $fullFileName )
	{
	   $self->addStatusLog("File $fullFileName exists! Not going to be downloaded!");
       print "...Not downloading because ".$fullFileName." exists!\n";   
 	   return;
	}	
	else
	{
		my $cleanURL = URI::Heuristic::uf_urlstr($urlName);
		$| = 1; # to flush next line
		my $browser = LWP::UserAgent->new();
		$browser->agent("Schmozilla/v9.14 Platinum"); # give it time, it'll get there
		my $req = HTTP::Request->new(GET => $cleanURL);
		$req->referer("http://wizard.yellowbrick.oz"); # perplex the log analysers
		
		my $response = $browser->request($req);
		if ( $response->is_success )
		{
			 unless (open(FILEOUT,">".$fullFileName)) {
			 	my @errorLog = @{$self->{errorLog}};
                $self->addErrorLog("Could not open file $fullFileName. $!");
                print "...Failure! Cound not open file ".$fullFileName."\n";
                return;
             }
			 binmode(FILEOUT);
			 my $content = $response->content(); 
			 print FILEOUT $content;
			 close FILEOUT;
			 my $bytes = length $content;
			 $self->addStatusLog("Success: File $fullFileName downloaded successfully! ".$bytes." Bytes\n");
			 print "...Success!\n"; 
			 return;
		}
		else
		{
			$self->addErrorLog("URL $urlName not found!");
			$self->addErrorLog("".$response->status_line);
			print "...Failure! ".$response->status_line."\n";
			return;
		}
	}
}

## 
sub addStatusLog()
{
	my $self = shift;
	push(@{$self->{statusLog}},shift);
}

## 
sub addErrorLog()
{
	my $self = shift;
	push(@{$self->{errorLog}},shift);
}


##
sub clone {
	my $model = shift;
	my $self = $model->new(%$model, @_);
	return $self;  # Previously blessed by ->new	
}

###
sub toString{
	my $self = shift;
	my $str = sprintf("URL: %s, Dir:%s, File: %s \nFullFileName: %s", $self->getUrlName(), $self->getDirName(), $self->getFileName(),$self->getFullFileName());

    # Status Log
    my @statusLog = @{$self->{statusLog}};
	$str = $str."\nStatus Log:".($#statusLog+1)."\n";
	my $count = 1;
	foreach my $statusLogElem ( @statusLog)
    {
    	$str  = $str."\t[$count] $statusLogElem\n";
    	$count = $count + 1;
    }
    # Error Log
    my @errorLog = @{$self->{errorLog}};
    $str = $str."Error Log:".($#errorLog+1)."\n";
    $count = 1;
    foreach my $errorLogElem (@errorLog)
    {
       $str = $str."\t[$count] $errorLogElem \n";
       $count = $count + 1;	
    }
    
	return $str;
}

###
sub toStringHTML{
	my $self = shift;
	my $str = "";  
    $str = $str."<UL>\n";
    $str = $str."<LI><B>URL: </B>".$self->getUrlName()." </LI>\n";
    $str = $str."<LI><B>DIR: </B>".$self->getDirName()." </LI>\n";
    $str = $str."<LI><B>FILE: </B>".$self->getFileName()." </LI>\n";
    ##
    my $statusLogRef = \@{$self->{statusLog}};
    my @statusLog = @$statusLogRef;
    $str = $str."<LI><B>Download Element Status Log [".($#statusLog + 1)."] Messages</LI></B>\n";
    $str = $str."<OL>\n";
	foreach my $statusLogElem ( @statusLog)
    {
    	$str  = $str."<LI style=\"color:green\"> $statusLogElem\n";
    }
    $str = $str."</OL>\n";
    ##
    my $errorLogRef =  \@{$self->{errorLog}};
    my @errorLog = @$errorLogRef;
    $str = $str."<LI><B>Download Element Error Log [".($#errorLog + 1) ."] Messages</LI></B>\n";
    $str = $str."<OL>\n";
	foreach my $errorLogElem ( @errorLog)
    {
    	$str  = $str."<LI style=\"color:red\"> $errorLogElem\n";
    }
    $str = $str."</OL>\n";
    $str = $str."</UL>\n";
    return $str;
}


###############################################################################
###############################################################################
###############################################################################
###############################################################################
###############################################################################
###############################################################################
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::Download::XMLScripted::XMLScripted - Perl XML scripted download program

=head1 SYNOPSIS

  use Net::Download::XMLScripted::XMLScripted;
  
  To Run from Command Line:
  
  (1) perl XMLScripted.pm -inXMLFileName xmlFileName [-verbose]

  (2) perl XMLScripted.pm -inXMLFileName xmlFileName -beginDate YYYY-MM-DD [-endDate YYYY-MM-DD]

  (3) perl XMLScripted.pm -generateSampleXMLFile sampleXMLFileName

  (4) perl XMLScripted.pm -showTranslationRules

  (5) perl XMLScripted.pm -version

=head1 DESCRIPTION

This is a daily download program. The input is an XML file that has information
about URLs that need to be downloaded. It uses specific translation rules to
generate URL names that contain dates. It creates directories specified in
the input XML file and downloads the URLs. This module is ideal for cron jobs.


=head2 EXPORT

None by default.



=head1 SEE ALSO

perl(1) LWP::UserAgent HTTP::Request HTTP::Response URI::Heuristic XML::Parser


=head1 AUTHOR

Singh T. Junior, E<lt>tsingh@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Singh T. Junior      

All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut



package Net::Download::XMLScripted::XMLScripted;

use Switch; 
use XML::Parser; 
#use IO;
use Time::Local;
use 5.008006;


use strict;


use vars qw($x $y $tree %translationHash);

## Get Translated StringCore
## Private method
## 
my $getTranslatedStringCore = sub 
{
   	my $self = shift;
   	my $inputString = shift;
   	my $myHash = shift;
   	my %myTranslationHash = %{$myHash};
   	my $outputString;
   	my $inputPattern;
   	
   	#
   	$outputString = sprintf("%s",$inputString);
   	while ( my ($key, $value) = each(%myTranslationHash) ) {
        $inputPattern = "\\[".$key."\\]"; 
   	    $outputString =~ s/$inputPattern/$value/g;	
    }
   	return $outputString;
};

## addStatusLog
## Private Method
## 
my $addStatusLog = sub 
{
	my $self = shift;
	push(@{$self->{statusLog}},shift);
};

## addErrorLog
## Private Method
##
my $addErrorLog = sub 
{
	my $self = shift;
	push(@{$self->{errorLog}},shift);
};


## Create TranslationHash Core
## Private method
##
my $createTranslationHashCore = sub 
{
    my $self = shift;
    my $TIME = shift;
    my @monthNames = ("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December");
	my @dayNames   = ("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday");
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($TIME);
	$mon += 1;
    $year += 1900;
    $yday += 1;
    
    my %translationHash = ();
    
    # Year, Month, Day
    $translationHash{'YYYY'} = $year; 
    $translationHash{'YY'}   = $year-2000;
    $translationHash{'MM'}   = $mon;
    $translationHash{'DD'}   = $mday;
    # 
    $translationHash{'YY_2'} = sprintf("%02d",$year-2000);
    $translationHash{'MM_2'} = sprintf("%02d",$mon);
    $translationHash{'DD_2'} = sprintf("%02d",$mday);
    #
    # Week day
    if ( $wday == 0 ) 
    {
    	$wday = 7;
    }
    $translationHash{'WD'} = $wday;
    #
    $translationHash{'DayOfWeek'} = $dayNames[$wday-1];
    
    $translationHash{'DAYOFWEEK'} = uc $translationHash{'DayOfWeek'};
    $translationHash{'dayofweek'} = lc $translationHash{'DayOfWeek'};
    $translationHash{'DayOfWeek_Abr'} = substr $translationHash{'DayOfWeek'}, 0, 3;
    $translationHash{'DAYOFWEEK_ABR'} = uc $translationHash{'DayOfWeek_Abr'};
    $translationHash{'dayofweek_abr'} = lc $translationHash{'DayOfWeek_Abr'};
    # Month
    $translationHash{'MonthOfYear'} = $monthNames[$mon-1];
   
    $translationHash{'MONTHOFYEAR'} = uc $translationHash{'MonthOfYear'};
    $translationHash{'monthofyear'} = lc $translationHash{'MonthOfYear'};
    $translationHash{'MonthOfYear_Abr'} = substr $translationHash{'MonthOfYear'}, 0, 3;
    $translationHash{'MONTHOFYEAR_ABR'} = uc $translationHash{'MonthOfYear_Abr'};
    $translationHash{'monthofyear_abr'} = lc $translationHash{'MonthOfYear_Abr'};
    ##
    $translationHash{'DayOfYear'} = $yday;
    $translationHash{'DayOfYear_2'} = sprintf("%02d",$yday);
    $translationHash{'DayOfYear_3'} = sprintf("%03d",$yday);
    ##
    $translationHash{'HH24'} = $hour;
    $translationHash{'HH24_2'} = sprintf("%0d",$hour);
    if ($hour < 12 )
    {
    	$translationHash{'HH12'}  = $hour;
    	$translationHash{'HH12_2'} = sprintf("%02d",$hour);
    	$translationHash{'AMPM'} = "AM";
    	$translationHash{'ampm'} = "am";
    }    
    else
    {
    	$translationHash{'HH12'} = $hour - 12;
    	$translationHash{'HH12_2'} = sprintf("%02d",$hour-12);
    	$translationHash{'AMPM'} = "PM";
    	$translationHash{'ampm'} = "pm";
    }
    ##
    $translationHash{'mm'} = $min;
    $translationHash{'mm_2'} = sprintf("%02d",$min);
    ##
    $translationHash{'ss'} = $sec;
    $translationHash{'ss_2'} = sprintf("%02d",$sec);
    
	##
	return %translationHash;
};

## makeElementDirectories
## Private method
##
my $makeElementDirectories = sub 
{
	my $self = shift;	
	my $fullDirName = $self->getFullDirectoryName();
	unless ( -d $fullDirName )
	{
		return;
	}
	#
	my @elementArray = @{$self->{elementArray}};
	foreach my $elem ( @elementArray )
    {
        my $fullElementDirName = $self->getFullFileName($fullDirName, $elem->getDirName());
        if ( -d $fullElementDirName )
        {
        	$elem->addStatusLog("Directory ".$fullElementDirName." Exists!");
        }    	
        else
        {
        	$elem->addStatusLog("Directory ".$elem->getDirName()." Does Not Exist!");
        	$elem->addStatusLog("Trying to create directory: ".$elem->getDirName());
        	unless ( mkdir($fullElementDirName, 0755) )
        	{
        		$elem->addStatusLog("Could not create directory: ".$elem->getDirName());
        	}
        	if ( -d $fullElementDirName )
        	{
        	    $elem->addStatusLog("Created the directory successfully: ".$fullElementDirName);
        	}
        }
    }
};

## MakeDirectories
## Private Method
##
my $makeDirectories = sub 
{
   my $self = shift;
   # Make sure the download path exists
   if ( -d $self->getDownLoadPathName() )
   {
   	  $self->$addStatusLog("Download Path Name ".$self->getDownLoadPathName()." Exists!");
   }
   else
   {
   	  $self->$addErrorLog("Error: Download Path Name ".$self->getDownLoadPathName()." Does Not Exist!");
   	  $self->$addStatusLog("Trying to create directory: ".$self->getDownLoadPathName());
   	  #
   	  unless ( mkdir($self->getDownLoadPathName(), 0755) )
   	  {
   	  	$self->$addErrorLog("Error: Could not create directory: ".$self->getDownLoadPathName());
   	  	return;
   	  } 
   	  #
   	  $self->$addStatusLog("Created the directory successfully: ".$self->getDownLoadPathName());
   }
   #
   my $fullDirName;
   if ( -d $self->getDownLoadPathName() )
   {
   	   $fullDirName = $self->getFullDirectoryName();
   	   if ( -d $fullDirName )
   	   {
   	   	  $self->$addStatusLog("Download Path to ".$self->getDownLoadDirName()." Exists!");
   	   }
   	   else
   	   {
   	   	  $self->$addErrorLog("Error: Download Dir Name ".$fullDirName." Does Not Exist!");
   	   	  $self->$addStatusLog("Trying to create directory: ".$fullDirName);
   	   	  unless ( mkdir ($fullDirName, 0755) )
   	   	  {
   	   	  	$self->$addErrorLog("Error: Could not create directory: ".$fullDirName);
   	   	  	return;
   	   	  }
   	   	  $self->$addStatusLog("Created the directory successfully ".$self->getDownLoadDirName());
   	   }
   }
   return;	
};

############################################################
## methods to access per-object data                      ##
############################################################
# initialize()
# Private method
my $initialize_XMLScripted = sub  {
	my $self = shift;
    $self->setDownLoadPathName("");
    $self->setDownLoadDirName("");
    $self->setStatusReportFileName("");
    %translationHash = ();
    $self->{statusLog} = ();
    $self->{errorLog} = ();
    $self->{elementArray} = ();
};


############################################################
## the object constructor                                 ##
############################################################
sub new {
   my $invocant = shift;
   my $class = ref($invocant) || $invocant; # Object or class name
   my $self  = {@_};
   bless ($self, $class);
   $self->$initialize_XMLScripted();
   return $self;	
}



# setDownLoadPathName()
sub setDownLoadPathName() {
	my $self = shift;
	$self->{downLoadPathName} = shift;
}

# getDownLoadPathName()
sub getDownLoadPathName()
{
	my $self = shift;
	return $self->{downLoadPathName};
}

# setDownLoadDirName()
sub setDownLoadDirName() {
	my $self = shift;
	$self->{downLoadDirName} = shift;
}

# getDownLoadDirName()
sub getDownLoadDirName()
{
	my $self = shift;
	return $self->{downLoadDirName};
}

# setStatusReportFileName()
sub setStatusReportFileName() {
	my $self = shift;
	$self->{statusReportFileName} = shift;
}

# getStatusReportFileName()
sub getStatusReportFileName()
{
	my $self = shift;
	return $self->{statusReportFileName};
}


# Generate full path name, and append the file separator character to
# the dirName if necessary
# getFullFileName(dirName, fileName)
sub getFullFileName()
{
	my $self = shift;
	my $dirName = "";
	my $fileName = "";
	$dirName = shift;
	$fileName = shift;
	
	if ( $self->getOperatingSystem() =~ m/LINUX/i )
	{
		# Check if file separator exists
		if (  $dirName =~ m/\/$/ )
		{
		   # Good, do nothing here. 	
		}
		else
		{
			# Append the file separator
			$dirName = $dirName."/";
		}
	}	
	else # Windows
	{
		# Check if file separator exists
		if (  $dirName =~ m/\\$/ )
		{
		   # Good, do nothing here. 	
		}
		else
		{
			# Append the file separator
			$dirName = $dirName."\\";
		} 
	}
	my $str = sprintf("%s%s",$dirName,$fileName);
	
	return $str;
}

=item sub getTranslationRules()

The function getTranslationRules() return a string that contains translation grammar.

=cut

sub getTranslationRules()
{
	my $str = "";
$str = "<!-- Convention:
#
# Translator for URLs and path names according to the Singh's rules
# 
# 
# Convention:
#
#     YYYY   - Year, Ex: 2006
#     YY     - Year, Ex: 1, 2, ...., 99
#     MM     - Month, 1, ..., 12
#     DD     - Day, 1, ..., 31
#     
#     YY_2   - Year with at 2 digits, 01, 02, ..., 99
#     MM_2   - Month (always 2 digits), 01, 02, ..., 12
#     DD_2   - Day   (always 2 digits), 01, 02, ..., 31
#     
#     DayOfWeek - Monday, Tuesday, ..., Sunday
#     DAYOFWEEK - MONDAY, TUESDAY, ..., SUNDAY
#     dayofweek - monday, tuesday, ..., sunday
#     DayOfWeek_Abr - Mon, Tue, ..., Sun
#     DAYOFWEEK_ABR - MON, TUE, ..., SUN
#     dayofweek_abr - mon, tue, ..., sun
#     WD     - Day of the week, 1, 2, 3, 4, 5, 6, 7
#     
#     MonthOfYear - January, February, ..., December
#     MONTHOFYEAR - JANUARY, FEBRUARY, ..., DECEMBER
#     monthofyear - january, february, ..., december
#     MonthOfYear_Abr - Jan, Feb, Mar, Apr, ..., Dec
#     MONTHOFYEAR_ABR - JAN, FEB, MAR, APR, ..., DEC
#     monthofyear_abr - jan, feb, mar, apr, ..., dec 
#
#     DayOfYear - 1, 2, 3, ....., 365
#     DayOfYear_2 - DayOfYear with at least 2 digits, 01, 02, ..., 365
#     DayOfYear_3 - DayOfYear with at least 3 digits, 001, 002, ..., 365
#     
#     HH24 - Hour,   1, 2, 3, ..., 24
#     HH12 - Hour,   1, 2, 3, ..., 12
#     HH24_2 - Hour with at least 2 digits, 01, 02, ..., 24
#     HH12_2 - Hour with at least 2 digits, 01, 02, ..., 12
#     mm - minutes, 0, 1, 2, ..., 59
#     mm_2 - minutes with at least 2 digits, 01, 02, ..., 59
#     ss  - seconds, 0, 1, 2, ..., 59
#     ss_2 - seconds with at least 2 digits, 01, 02, ..., 59
#     
#     AMPM - AM or PM
#     ampm - am  or pm
#
#     OFFSETS:
#     -nD - n Day offset  for example [DD-1D], [DD-3D]
#     -nW - n Week offset  for example [DD-1W], [DD-3W]
#     -nM - n Month offset  for example [DD-1M], [DD-3M]
#     -nY - n Year offset  for example [DD-1Y], [DD-3Y]
#   
-->\n";
  return $str;
}

=item sub createTranslationHash()

The function createTranslationHash() generates the hash that contains the translation rules.
It's input argument is an Epoch Time variable. 

Example: $cio->createTranslationHash(time);

=cut

sub createTranslationHash()
{
	my $self = shift;
    my $TIME = shift;
    %translationHash = $self->$createTranslationHashCore($TIME);
}




## Get Translated String
sub getTranslatedString()
{
   	my $self = shift;
   	my $inputString = shift;
   	my $outputString;
   	$outputString = $self->$getTranslatedStringCore($inputString, \%translationHash);
    
    ## Look for offsets
    while ( $outputString =~ m/\[(.)*([+|-])(\d)[DWMY]\]/ )
    {
       # More to go 
       while ( my ($key, $value) = each(%translationHash) ) 
       {
       	     # Day Offsets
        	 if ( $outputString =~ m/\[$key([-|+])(\d+)D\]/ )
        	 {
        	 	my $mySign = $1;
        	 	my $myDayOffset = $2;
        	 	my $myPattern;
        	 	if ( $mySign =~ m/-/ )
        	 	{
        	 		$myDayOffset = -1 * $myDayOffset;
        	 		if ( $myDayOffset != 0 )
        	 		{
        	 		  $myPattern = sprintf("%s%dD",$key,$myDayOffset);
        	 		}
        	 		else
        	 		{
        	 		  $myPattern = sprintf("%s-0D",$key);
        	 		}
        	 	}
        	 	else
        	 	{
        	 		$myPattern = sprintf("%s\\+%dD",$key,$myDayOffset);
        	 	}
        	 	my $myTime = time;
        	 	$myTime = $myTime + $myDayOffset * 24 * 60 * 60;
        	 	$outputString =~ s/\[$myPattern\]/\[$key\]/g;
        	 	my %offsetTranslationHash = $self->$createTranslationHashCore($myTime);
        	 	$outputString = $self->$getTranslatedStringCore($outputString, \%offsetTranslationHash);
        	 }
        	 # Week Offsets
        	 if ( $outputString =~ m/\[$key([-|+])(\d+)W\]/ )
        	 {
        	 	my $mySign = $1;
        	 	my $myWeekOffset = $2;
        	 	my $myPattern;
        	 	if ( $mySign =~ m/-/ )
        	 	{
        	 		$myWeekOffset = -1 * $myWeekOffset;
        	 		if ( $myWeekOffset != 0 )
        	 		{
        	 		  $myPattern = sprintf("%s%dW",$key,$myWeekOffset);
        	 		}
        	 		else
        	 		{
        	 		  $myPattern = sprintf("%s-0W",$key);
        	 		}
        	 	}
        	 	else
        	 	{
        	 		$myPattern = sprintf("%s\\+%dW",$key,$myWeekOffset);
        	 	}
        	 	my $myTime = time;
        	 	$myTime = $myTime + $myWeekOffset * 7 * 24 * 60 * 60;
        	 	$outputString =~ s/\[$myPattern\]/\[$key\]/g;
        	 	my %offsetTranslationHash = $self->createTranslationHashCore($myTime);
        	 	$outputString = $self->getTranslatedStringCore($outputString, \%offsetTranslationHash);
        	 }
        	 # Month Offsets
        	 if ( $outputString =~ m/\[$key([-|+])(\d+)M\]/ )
        	 {
        	 	my $mySign = $1;
        	 	my $myMonthOffset = $2;
        	 	my $myPattern;
        	 	if ( $mySign =~ m/-/ )
        	 	{
        	 		$myMonthOffset = -1 * $myMonthOffset;
        	 		if ( $myMonthOffset != 0 )
        	 		{
        	 		  $myPattern = sprintf("%s%dM",$key,$myMonthOffset);
        	 		}
        	 		else
        	 		{
        	 		  $myPattern = sprintf("%s-0M",$key);
        	 		}
        	 	}
        	 	else
        	 	{
        	 		$myPattern = sprintf("%s\\+%dM",$key,$myMonthOffset);
        	 	}
        	 	my $myTime = time;
        	 	$myTime = $myTime + $myMonthOffset * 30 * 24 * 60 * 60;
        	 	$outputString =~ s/\[$myPattern\]/\[$key\]/g;
        	 	my %offsetTranslationHash = $self->createTranslationHashCore($myTime);
        	 	$outputString = $self->getTranslatedStringCore($outputString, \%offsetTranslationHash);
        	 }
        	 # Year Offsets
        	 if ( $outputString =~ m/\[$key([-|+])(\d+)Y\]/ )
        	 {
        	 	my $mySign = $1;
        	 	my $myYearOffset = $2;
        	 	my $myPattern;
        	 	if ( $mySign =~ m/-/ )
        	 	{
        	 		$myYearOffset = -1 * $myYearOffset;
        	 		if ( $myYearOffset != 0 )
        	 		{
        	 		  $myPattern = sprintf("%s%dY",$key,$myYearOffset);
        	 		}
        	 		else
        	 		{
        	 		  $myPattern = sprintf("%s-0Y",$key);
        	 		}
        	 	}
        	 	else
        	 	{
        	 		$myPattern = sprintf("%s\\+%dY",$key,$myYearOffset);
        	 	}
        	 	my $myTime = time;
        	 	$myTime = $myTime + $myYearOffset * 365 * 24 * 60 * 60;
        	 	$outputString =~ s/\[$myPattern\]/\[$key\]/g;
        	 	my %offsetTranslationHash = $self->createTranslationHashCore($myTime);
        	 	$outputString = $self->getTranslatedStringCore($outputString, \%offsetTranslationHash);
        	 }
       }
    }
    
   	return $outputString;
}



## Parse input xml file
sub parseXMLFile()
{
	my $self = shift;
	my $xmlfile = shift;
    my $parser;
    die "Can't find file \"$xmlfile\"" unless -f $xmlfile;

    # initialize parser object and parse the string
    $parser = new XML::Parser(ErrorContext => 2, Style => 'Tree' );
    $tree = $parser->parsefile($xmlfile);
    # report any error that stopped parsing, or announce success
    if ( $@ ) 
    {
       $@ =~ s/at \/.*?$//s;    # remove module line number
       #print STDERR "\nERROR in '$xmlfile':\n$@\n";
       $self->$addErrorLog("Error in $xmlfile. $@");
       return;
    }
    else
    {
    	#print STDERR "'$xmlfile' is well-formed\n";
    	$self->$addStatusLog("The XML file $xmlfile is well-formed");
    }
    # 

    my ($i, $j, $k);
    no strict 'refs';
    # Parse nodes at the first level
    for $i ( 0 .. $#{$tree} ) {
        for $j ( 0 .. $#{$tree->[$i]} ) {
            # Download Path Name
            if ( $tree->[$i][$j] eq "downLoadPathName" )
            {
            	$self->setDownLoadPathName($self->getTranslatedString($self->trim($tree->[$i][$j+1][2])));
            }
            # Download Directory Name
            elsif ( $tree->[$i][$j] =~ "downLoadDirName" )
            {
            	$self->setDownLoadDirName($self->getTranslatedString($self->trim($tree->[$i][$j+1][2])));	
            }
            # Status Report File Name
            elsif ( $tree->[$i][$j] =~ "statusReportFileName" )
            {
            	$self->setStatusReportFileName($self->getTranslatedString($self->trim($tree->[$i][$j+1][2])));
            }
            # Entry
            elsif ( $tree->[$i][$j] =~ "entry" )
            {
            	my $elemento  = Net::Download::XMLScripted::XMLScriptedElement::->new();
            	for $k ( 0  .. $#{$tree->[$i][$j+1]} )
            	{
            		# URL
            		if ( $tree->[$i][$j+1][$k] eq "url" )
            		{
            			$elemento->setUrlName($self->getTranslatedString($self->trim($tree->[$i][$j+1][$k+1][2])));
            		}
            		# dirName
            		if ( $tree->[$i][$j+1][$k] eq "dirName" )
            		{
            			$elemento->setDirName($self->getTranslatedString($self->trim($tree->[$i][$j+1][$k+1][2])));
            		}
            		# fileName
            		if ( $tree->[$i][$j+1][$k] eq  "fileName" )
            		{
            			$elemento->setFileName($self->getTranslatedString($self->trim($tree->[$i][$j+1][$k+1][2])));
            		}
            	}
            	#
            	push @{$self->{elementArray}}, $elemento;
            }
        }
    }
    $self->generateFullFileNames();
}

##
sub generateFullFileNames()
{
	my $self = shift;
	my @elementArray = @{$self->{elementArray}};
	#
    foreach my $elem ( @elementArray )
    {
    	my $str = $self->getFullFileName($self->getDownLoadPathName(),$self->getDownLoadDirName());
    	$str =    $self->getFullFileName($str, $elem->getDirName());
    	$str =    $self->getFullFileName($str, $elem->getFileName());
    	$elem->setFullFileName($str);
    }
}

###
sub toString{
	my $self = shift;
	my @elementArray = @{$self->{elementArray}};
	my $str = "XMLScripted\n";
    $str = $str.sprintf("DownLoadPath: %s, DownLoadDir: %s ",$self->getDownLoadPathName(), $self->getDownLoadDirName());
    $str = $str."\n\n";
    $str = $str."Number of Elements in Array: ".($#elementArray+1);
    $str = $str."\n\n";
    my $count = 1;
    
    # Element array
    my $object;
    foreach $object( @elementArray )
    {
    	next unless ref $object;
    	$str = $str. sprintf("[%d] %s\n",$count, $object->toString());
    	$count = $count + 1;
    }
    
    # Status Log
    my @statusLog = @{$self->{statusLog}};
	$str = $str."\nXMLScripted Status Log: ".($#statusLog+1)."\n";
	$count = 1;
	foreach my $statusLogElem ( @statusLog)
    {
    	$str  = $str."\t[$count] $statusLogElem\n";
    	$count = $count + 1;
    }
    
    # Error Log
    my @errorLog = @{$self->{errorLog}};
    $str = $str."XMLScripted Error Log: ".($#errorLog+1)."\n";
    $count = 1;
    foreach my $errorLogElem (@errorLog)
    {
       $str = $str."\t[$count] $errorLogElem \n";
       $count = $count + 1;	
    }
    return $str;	
}

###
sub toStringHTML{
	my $self = shift;
    my $str;
    $str    =  $str. "<HTML>\n";
    $str    =  $str.     "<HEAD>\n";
    $str    =  $str.   "<TITLE>";
    $str    =  $str.   "XMLScripted Status Report";
    $str    =  $str.    "</TITLE>\n";
    $str    =  $str.    "</HEAD>\n";
    $str    =  $str.    "<BODY>\n";
    $str    =  $str.    "<CENTER><H1>";
    $str    =  $str.    "XMLScripted Status Report";
    $str    =  $str.    "</H1></CENTER>\n";
    $str    =  $str.    "<CENTER>".$self->getDateTimeStamp()."</CENTER>\n";
    $str    =  $str.    "<UL>\n";
    $str    =  $str.    "<LI>";
    $str    =  $str.    "<B>Download Path Name: </B> $self->{downLoadPathName}\n";
    $str    =  $str.    "</LI>\n";
    $str    =  $str.    "<LI>";
    $str    =  $str.    "<B>Download Directory Name: </B> $self->{downLoadDirName}\n";
    $str    =  $str.    "</LI>\n";
    $str    =  $str.    "<LI>";
    $str    =  $str.    "<B>Status Report File Name: </B>".$self->getFullFileName($self->getFullDirectoryName(),$self->getStatusReportFileName())."\n";
    $str    =  $str.    "</LI>\n";
    $str    =  $str.    "<LI>";
    $str    =  $str.    "<B>Number of Download Elements: </B>".$self->getNumberOfElements()."\n";
    $str    =  $str.    "</LI>\n";
    $str    =  $str.    "</UL>\n";
    # Status Log
    my $statusLogRef = \@{$self->{statusLog}};
    my @statusLog = @$statusLogRef;
    $str     =  $str.    "<H2>XMLScripted Status Log [".($#statusLog+1)."] Messages</H2>\n"; 
    $str     = $str.    "<OL>\n";
	foreach my $statusLogElem ( @statusLog)
    {
    	$str  = $str."<LI style=\"color:green\"> $statusLogElem\n";
    }
    $str     = $str.    "</OL>\n";
    # Error Log
    my $errorLogRef =  \@{$self->{errorLog}};
    my @errorLog = @$errorLogRef;
    $str     =  $str.    "<H2>XMLScripted Error Log [".($#errorLog+1)."] Messages</H2>\n"; 
    $str     = $str.    "<OL>\n";
	foreach my $errorLogElem ( @errorLog)
    {
    	$str  = $str."<LI style=\"color:red\"> $errorLogElem\n";
    }
    $str     = $str.    "</OL>\n";
    $str    =  $str.    "<CENTER><H1>";
    $str    =  $str.    "XMLScripted Download Elements Status Report";
    $str    =  $str.    "</H1></CENTER>\n";
    # Element array
    my $object;
    my $count = 1;
    foreach $object( @{$self->{elementArray}} )
    {
    	next unless ref $object;
    	$str = $str."<H2>$count. Download Element</H2>\n";
    	$str = $str. sprintf("%s\n", $object->toStringHTML());
    	$count = $count + 1;
    }
    $str    =  $str.    "</BODY>\n";
    $str    =  $str. "</HTML>\n";
}

##
sub getNumberOfElements()
{
  my $self = shift;
  my $count = 0;
  foreach my $object( @{$self->{elementArray}} )
  {
   	$count = $count + 1;
  }
  return $count;	
}

##
sub getDateTimeStamp()
{
	my $self = shift;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
	my $str = sprintf( "%4d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);
	return $str;
}

##
sub getDateStamp()
{
	my $self = shift;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime();
	my $str = sprintf( "%4d-%02d-%02d",$year+1900,$mon+1,$mday);
	return $str;
}



##
sub clone {
	my $model = shift;
	my $self = $model->new(%$model, @_);
	return $self;  # Previously blessed by ->new	
}


## Print Translation Hash
sub printTranslationHash()
{
	print "Translation Hash:\n";
	$~ = 'FORMAT_TRANS';
	$x = "Key";
	$y = "Value";
	write();
	while ( my ($key, $value) = each(%translationHash) ) {
        $x = "[".$key."]";
        $y = $value;
        write();
    }
}

## Get Translation Hash
sub getTranslationHashToString()
{
	my $str =  "#Translation Hash:\n";
	while ( my ($key, $value) = each(%translationHash) ) {
        $str = $str.sprintf("#\t[%s] \t%s\n", $key, $value);
    }
    return $str;
}

=item  sub download()

The function dowload() performs the download operations. This includes creation of required directories.

=cut

sub download()
{
	my $self = shift;
	$self->$makeDirectories();
	$self->$makeElementDirectories();
	my @elementArray = @{$self->{elementArray}};
	foreach my $elem ( @elementArray )
    {
    	$elem->download();
    }
}

=item sub getFullDirectoryName()

This function returns full Directory name given a main path and a subdirectory.

=cut 

sub getFullDirectoryName()
{
  my $self = shift;
  return $self->getFullFileName($self->getDownLoadPathName(), $self->getDownLoadDirName());
}

##
sub getEpochTimeFromDate()
{
	my $self = shift;
	my $date = shift;
    my ($yy, $mm, $dd);
	#
	    ($yy,$mm, $dd) = ( $date =~ /(\d+)-(\d+)-(\d+)/);
	    $mm = $mm-1;
	    $yy = $yy-1900;
	    my $TIME = timelocal((localtime)[0,1,2],$dd, $mm, $yy);
        return $TIME;
}

##
sub getDateFromEpochTime()
{
    my $self = shift;
    my $myTime = shift;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime($myTime);
	my $str = sprintf( "%04d-%02d-%02d",$year+1900,$mon+1,$mday);
	return $str;
}

=item sub writeStatusReport()

This function creates status report in the download directory.

=cut

sub writeStatusReport()
{
  my $self = shift;
  
  unless ( -d $self->getFullDirectoryName() )
  {
  	$self->addErrorLog("Error: Could not create Status Report because directory ".$self->getFullDirectoryName());
  	return;
  }
  my $fullStatusFileName = $self->getFullStatusReportFileName();
  unless ( open(STATUS, ">$fullStatusFileName") )
  {
  	$self->addErrorLog("Error: Could not create Status Report. Not able to create $fullStatusFileName. $!");
  	return;
  }
  print STATUS $self->toStringHTML();
  close STATUS;
  
}

## 
sub getFullStatusReportFileName()
{
   my $self = shift;
   my $fullStatusFileName = $self->getFullFileName($self->getFullDirectoryName(),$self->getStatusReportFileName());
   return $fullStatusFileName;
}

=item  sub getOperatingSystem()

The getOperatingSystem() function returns the type of Operating System.

=cut

sub getOperatingSystem()
{
	my $OS = '';
	unless ($OS) {
	   unless ($OS = $^O) {
	   	 require Config;
	   	 $OS = $Config::Config{'osname'};
	   }
	}	
	if ( $OS =~    m/Win/i ) { $OS = 'WINDOWS'; }
	elsif ( $OS =~ m/vms/i) { $OS = 'VMS'; }
	elsif ( $OS =~ m/^MacOS$/i) { $OS = 'MACINTOSH'; }
	elsif ( $OS =~ m/os2/i) { $OS = 'OS2'; }
	else  { $OS = 'LINUX'; }
	return $OS;
}

## trim
## Public method
sub trim  {
	my $self = shift;
    my @out = @_;
    for (@out) {
        s/^\s+//; # discard leading whitespace
        s/\s+$//; # discard trailing whitespace
    }
    return wantarray ? @out : $out[0];
}

##
format FORMAT_TRANS= 
@<<<<<<<<<<<<<<<<<<<< ... @<<<<<<<<<<<<<<<<<<<
$x,                        $y
.

=item sub printUsage()

This program prints the usage of mainXMLScripted.

=cut
##
sub printUsage()
{
  my $self = shift;	
  print "Usage: perl XMLScripted.pm -inXMLFileName xmlFileName [-verbose]\n";
  print "Usage: perl XMLScripted.pm -inXMLFileName xmlFileName -beginDate YYYY-MM-DD [-endDate YYYY-MM-DD]\n";
  print "Usage: perl XMLScripted.pm -generateSampleXMLFile sampleXMLFileName\n";
  print "Usage: perl XMLScripted.pm -showTranslationRules\n";
  print "Usage: perl XMLScripted.pm -version\n";
}


=item sub getVersion()

Returns current version of the program.

=cut
## getVersion()
sub getVersion()
{
   my $self = shift;		
   my $str = "";
   $str = "".$VERSION;
   return $str;	
}

=item sub generateSampleXMLFile()

Generates sample XML file that can be modified and used as input.

=cut
## generateSampleXMLFile()
sub generateSampleXMLFile()
{
	my $self = shift;
	my $fileName = shift;
	print "Generating Sample XML File :".$fileName."\n";
	open(FILE, ">$fileName") or die "Could not open ".$fileName." $!\n ";
	print FILE <<EOF;
<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
<!DOCTYPE xmlscripted [
<!ELEMENT xmlscripted (downLoadPathName, downLoadDirName, statusReportFileName, entry+)>
<!ELEMENT downLoadPathName (#PCDATA)>
<!ELEMENT downLoadDirName  (#PCDATA)>
<!ELEMENT statusReportFileName (#PCDATA)>
<!ELEMENT entry (url, dirName, fileName)>
<!ELEMENT url (#PCDATA)>
<!ELEMENT dirName (#PCDATA)>
<!ELEMENT fileName (#PCDATA)>
]>
<!-- SAMPLE INPUT FILE FOR DAILY DOWNLOAD PROGRAM -->
EOF
    print FILE $self->getTranslationRules();
    print FILE<<EOF;
<xmlscripted>

<!-- Download Path Name -->
<downLoadPathName>/tmp/download.dir/</downLoadPathName>

<!-- Download Directory Name -->
<downLoadDirName>[YYYY]-[MM_2]-[DD_2].dir</downLoadDirName>

<!-- Status Report HTML File Name -->
<statusReportFileName>Status.html</statusReportFileName>

<!-- Entry -->
<entry>
<url>http://www.suntimes.com/cgi-bin/print.cgi?getReferrer=http://www.suntimes.com/output/horoscopes/cst-nws-holly[MM][DD].html</url>
<dirName>horoscope</dirName>
<fileName>horoscope.html</fileName>
</entry>

<!-- Entry -->
<entry>
<url>http://www.suntimes.com/cgi-bin/print.cgi?getReferrer=http://www.suntimes.com/output/lottery/cst-nws-lot[DD_2].html</url>
<dirName>lottery</dirName>
<fileName>lottery.html</fileName>
</entry>

<!-- Entry -->
<entry>
<url>http://transcripts.cnn.com/TRANSCRIPTS/[YYYY].[MM_2].[DD_2].html</url>
<dirName>news</dirName>
<fileName>news.html</fileName>
</entry>


</xmlscripted>
EOF
	close FILE;
	return;
}

=item sub runEngine()

This routine is responsible for performing the actual task. It's arguments are 
input xmlFileName, beginDate, and endDate. The format of date is YYYY-MM-DD. 
Ex: runEngine("/tmp/input.xml", "2007-07-04", "2007-07-04");

=cut
## runEngine()
sub runEngine()
{ 
	    my $self = shift;
	    my $xmlFile = shift;
	    my $beginDate = shift;
	    my $endDate = shift;
        print "The input XML File: ".$xmlFile."\n";
	    
	    my $BEGINTIME = $self->getEpochTimeFromDate($beginDate);
	    my $ENDTIME =   $self->getEpochTimeFromDate($endDate);
	    # 
	    my $interval = 1 * 24 * 60 * 60; ## one day in seconds
    	#
	    my $myTime = $BEGINTIME;
        #	
	    while ( $myTime <= $ENDTIME )
	    {
	       my $myDate = $self->getDateFromEpochTime($myTime);
	       print "Working on ".$myDate."\n";
	       $self->createTranslationHash($myTime);
	       $self->parseXMLFile($xmlFile);
	       $self->download();
	       $self->writeStatusReport();
	       print ">>>Status Report created at : ".$self->getFullStatusReportFileName()."\n";
	       $myTime = $myTime + $interval;
	    }
}


=item sub run()

This routine is called by the instance of the XMLScripted object and it
runs the program.

=over 4

=item * # Create XMLScripted Object

=item * my $cio = Net::Download::XMLScripted::XMLScripted::->new();

=item * # Run it 

=item * $cio->run();

=back 

=cut
sub run()
{
    my $self = shift;
    my $numArgs = $#ARGV + 1;
    print "Welcome to XMLScripted Program!\n";
	#
	if ( $numArgs == 0 )
	{
		$self->printUsage();
		print "XMLScripted Program Ended!\n";
	    exit(1);
	}

	#
	if ( $numArgs == 1 )
	{
	    if ( $ARGV[0] =~ /-showTranslationRules/ )
	    {
	       print $self->getTranslationRules()."\n";
	       print "XMLScripted Program Ended!\n";
	       exit(1);
	    }
	    elsif ( $ARGV[0] =~ /-version/ )
	    {
	    	print $self->getVersion()."\n";
	    	print "XMLScripted Program Ended!\n";
	        exit(1);
	    }
	    else
	    {
	    	$self->printUsage();
	    	print "XMLScripted Program Ended!\n";
	    	exit(1);
	    }	
	}

	#
	if ( $numArgs == 2 || $numArgs == 3 )
	{
		if ( $ARGV[0] =~ /-inXMLFileName/ )
		{
		  my $xmlFile = $ARGV[1];
		  my $myTime = time;
		  my $myDate = $self->getDateFromEpochTime($myTime);
		  my $beginDate = $myDate;
		  my $endDate   = $myDate;
		 
		  $self->runEngine($xmlFile, $beginDate, $endDate);
		  
		  if ( $numArgs == 3 )
		  {
		  	if ($ARGV[2] =~ /-verbose/ )
		  	{
		  		print $self->toString()."\n";
		  	}
		  }
		  print "XMLScripted Program Ended!\n";
		  exit(1);
		}
		elsif ( $ARGV[0] =~/-generateSampleXMLFile/ )
		{
			#
			my $sampleXMLFile = $ARGV[1];
			$self->generateSampleXMLFile($sampleXMLFile);
			print "XMLScripted Program Ended!\n";
			exit(1);
		}
		else
		{
	       $self->printUsage();
	       print "XMLScripted Program Ended!\n";
	       exit(1);
		}	
	}

	#
	if ( $numArgs == 4 )
	{
		if ( $ARGV[0] =~/inXMLFileName/ && $ARGV[2] =~ /-beginDate/ )
		{
			my $xmlFile = $ARGV[1];
			my $beginDate = $ARGV[3];
			my ($mday, $mon, $year);
		    ($mday, $mon, $year) = (localtime)[3,4,5];
			my $endDate   = sprintf("%04d-%02d-%02d",$year+1900,($mon+1),$mday);
		    
		    $self->runEngine($xmlFile, $beginDate, $endDate);
		}
		else
		{
			$self->printUsage();
	        print "XMLScripted Program Ended!\n";
	        exit(1);
		}
	}
	# 
	if ($numArgs == 6 )
	{
		if ( $ARGV[0] =~/inXMLFileName/ && $ARGV[2] =~ /-beginDate/ && $ARGV[4] =~ /-endDate/  )
		{
			my $xmlFile   = $ARGV[1];
			my $beginDate = $ARGV[3];
			my $endDate   = $ARGV[5];
		    
		    $self->runEngine($xmlFile, $beginDate, $endDate);
		}
		else
		{
			$self->printUsage();
	        print "XMLScripted Program Ended!\n";
	        exit(1);
		}
	}
    
}

###############################################################################
###############################################################################
###############################################################################
###############################################################################
###############################################################################
###############################################################################
# main program

use strict;
#
## Create XMLScripted Object
my $xmlScripted = Net::Download::XMLScripted::XMLScripted::->new();
if ( $#ARGV > -1 )
{
 $xmlScripted->run();
 exit(1);
}
#

1; # Let's require or use succeed
__END__

