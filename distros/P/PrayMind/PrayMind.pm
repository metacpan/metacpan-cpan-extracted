package Religion::Islam::PrayMind;

#
# Copyright (c) 2002 Tasmin Ahmad
# All rights reserved.
#
# Implements Class to connect and retrieve data from the PrayerMinder server
#
# This library is free software; you can redistribute it and/or modify
# it under the "Artistic License", as described in the accompanying
# License.txt file. 
#
#
# DISCLAIMER
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
# Acknowledgement
# The following people have contributed to the development of
# this tool, in addition to the copyright owner:
#
# 1. Mr. Tariq Chaudhary
# 2. Allied Software Corporation Islamabad, Pakistan; particularly the
#    following folks:
# 2.1 Mr. S. Taimur Hassan
# 2.2 Ms. Shaista Rashid
# 2.3 Mr. Ijaz Rashid
#

use IO::Socket;
use XML::Parser;


use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Religion::Islam::PrayMind ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw($VERSION 
	eContinentsList eCountriesList eStatesList
	eCitiesListForState eCitiesListForCountry 
	ePrayerTimes ePrayerTimeTable
	
	IDS_NO_Error IDS_ERROR_OpenNotCalled IDS_ERROR_ClientIDNotSpecified IDS_ERROR_EmptyString
	IDS_ERROR_GetListNotCalled IDS_ERROR_GetPrayerTimesNotCalled IDS_ERROR_EmptyList
);

our $VERSION = '1.01';

#define constant values for type of listing requested by caller
use constant eContinentsList => 0;
use constant eCountriesList => 1;
use constant eStatesList => 2;
use constant eCitiesListForState => 3;
use constant eCitiesListForCountry => 4;
use constant eCitiesSearchList => 5;
use constant ePrayerTimes => 6;
use constant ePrayerTimeTable => 7;

#define constant values for error codes
use constant IDS_NO_Error => 0;
use constant IDS_ERROR_OpenNotCalled => 1;
use constant IDS_ERROR_ClientIDNotSpecified => 2;
use constant IDS_ERROR_EmptyString => 3;
use constant IDS_ERROR_GetListNotCalled => 4;
use constant IDS_ERROR_GetPrayerTimesNotCalled => 5;
use constant IDS_ERROR_EmptyList => 6;

#define local constant values used to know type of listing obtained
use constant eNoData => 0;
use constant eLocationsList => 1;
use constant ePrayerTimings => 2;

use constant host => "www.prayerminder.com";
#use constant host => "209.185.200.148";
use constant EOL => "\015\012";
use constant BLANK => EOL x 2;

#class private global member variable declaration
#our ($host, $EOL, $BLANK);

#Hash to store error codes and their corresponding text
our @PMErrors =
(
 "No Errors",
 "Open function not called",
 "Client ID not specified",
 "Host returned an empty string please check that you have passed correct parameters",
 "Call GetList function first",
 "Call GetPrayerTimes function first",
 "List does not contain elements"
);

#function that will return class reference

sub new
{
  my ($class, %args) = @_;
  my $self = bless \%args, $_[0];
  if(!defined($args{ClientID}))
  {
	  $args{ErrorCode} = IDS_ERROR_ClientIDNotSpecified;
  }
  else
  {	
	$args{ErrorCode} = IDS_NO_Error;
	$args{_DataType} = eNoData;
	$args{_TimesData} =
		{
			nCityID => 0,
			nCountryId => 0,
			nStateID => 0,
			sCityTitle => '',
			sCityTimeZone => '',
			sCityIslamicDate => '',
			sCityGregorianDate => '',
			sCityAsrFiqh => '',
			CityPrayerTimes => {Fajr => "", Shurooq => "", Zuhr => "", AsrHanafi => "", AsrShafei => "", Maghrib => "", Isha => ""}
		};
	$args{_LocationsList} =
		{
			LocNames => [],
			LocIDs => [],
			nCurrItem => 0
		};
  }

  $self;
}

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

#sends HTTP query to obtain the list required and saves the result in run time structure
sub GetList
{
	#store parameters received to functions local variables
	my ($self, $ListType, $nParentID) = @_;

	my ($document, $nListType);
	$nListType = eNoData;
	
	#implementing error when GetList called before making a call to new function
	if(!defined($self->{ErrorCode}))
	{
		$self->{ErrorCode} = IDS_ERROR_OpenNotCalled;
	}

	if($self->{ErrorCode} != IDS_NO_Error)
	{
		return;
	}

	$document = "/cgi-bin/PMCalc.cgi?F=X&I=" . $self->{ClientID} . "&R=";
	
	#Get the required list if Open function called before calling it
	if($self->{ErrorCode} != IDS_ERROR_OpenNotCalled)
	{

		#now it depends upon $ListType which list to obtain
		
		#make the query string that will be passed to get continent, countrie and city listing
		#asked for continents list 
		if($ListType == eContinentsList)
		{
			$document = $document . "LCN";
		}
		#asked for countries list 
		elsif($ListType == eCountriesList)
		{
			$document = $document . "LCY&CN=";
			$document = $document . $nParentID;
		}
		#asked for cities list 
		elsif($ListType == eCitiesListForCountry)
		{
			$document = $document . "LCT&CY=";
			$document = $document . $nParentID;
		}
#print "  in GetList 1<BR>\n";
		#establish the connection to the host
		my ($remote, $StartData, $aline);
		$remote = IO::Socket::INET->new( Proto     => "tcp",
						 PeerAddr  => host,
						 PeerPort  => "http(80)",
					       );

#print "  in GetList , doc=" . $document . "<BR>\n";
		#error message to report if connection is not established with host
		unless($remote)
		{ 
			die "Cannot connect to http daemon on host " . host;
		}

		print $remote "GET $document HTTP/1.0" . BLANK;

		$StartData = 0;
		#$DesiredString = "";

		#while remote is returning cetain text
		while(($StartData < 1) && (defined ($aline = <$remote>)))
		{
#print " > " . $aline . "<br>\n";
			#check if line is a blank line, after which the XML document follows
			if($aline eq "\r\n")
			{
				$StartData = 1;
			}
		}
		
		# If we got any data, parse it
		if($StartData == 1)
		{
			# Make a call to function that will xml data returned by server
			# the XML data will be parsed by XML parser and information will be 
			# stored in class member variables
			ParseXMLFile($self, $remote, eLocationsList);
		}
		close $remote;
	
	#print "   *** GetList ErrorCode: " . $self->{ErrorCode} . " ErrorText: " . $self->{ErrorText} . "<BR>\n";

		#you get the required text from host
#		if($self->{_DataType} != eLocationsList)
#		{
			#discard errors previously set
			#Error Code IDS_ERROR_GetListNotCalled "Call GetList function first";
			#Error Code IDS_ERROR_GetPrayerTimesNotCalled "Call GetPrayerTimes function first";
			#Error Code IDS_ERROR_EmptyList "Empty List";
#			$self->{ErrorCode} = IDS_NO_Error
#				if($self->{ErrorCode} == IDS_ERROR_GetListNotCalled || $self->{ErrorCode} == IDS_ERROR_GetPrayerTimesNotCalled || 
#					$self->{ErrorCode} == IDS_ERROR_EmptyList);
#		}
		
		#check whether some string is returned by host
#		if($self->{_DataType} != eLocationsList)
#		{
#			$self->{ErrorCode} = IDS_ERROR_EmptyString
#				if($self->{ErrorCode}) == IDS_NO_Error;
#		}
		#discard error that was set that empty string returned by host

#		elsif($self->{ErrorCode} == IDS_ERROR_EmptyString)
#		{
#			$self->{ErrorCode} = IDS_NO_Error;
#		}
	}
}

#functions that are called when asked for listing of continents, countries and cities
#returns number of elements in the list retreived by GetList
sub GetListSize
{
	#store parameters received to functions local variables
	my $self = shift;

	#$nListType is set to  eLocationsList when asked for continents, countries or city listing
	if($self->{_DataType} != eLocationsList)
	{
		$self->{ErrorCode} = IDS_ERROR_GetListNotCalled;
		return -1;
	}
	else
	{
		#check for empty list
		if($#{$self->{_LocationsList}->{LocNames}} < 0)
		{
			$self->{ErrorCode} = IDS_ERROR_EmptyList;
		}
		return $#{$self->{_LocationsList}->{LocNames}} + 1;
	}
}

#returns parent element's ID, to which this list belongs
#sub GetParentID
#{
#	#$nListType is set to  eLocationsList when asked for continents, countries or city listing
#	if($nListType != eLocationsList)
#	{
#		$ErrorCode = IDS_ERROR_GetListNotCalled;
#		return -1;
#	}
#	else
#	{
#		return $ParentID;
#	}
#}

#returns ID of the current element from the list
sub GetElementID
{
	my $self = shift;

	#$nListType is set to  eLocationsList when asked for continents, countries or city listing
	if($self->{_DataType} != eLocationsList)
	{
		$self->{ErrorCode} = IDS_ERROR_GetListNotCalled;
		return -1;
	}
	else
	{
		return $self->{_LocationsList}->{LocIDs}->[$self->{_LocationsList}->{nCurrItem}];
	}
}

#returns the name of the current element from the list
sub GetElementName
{
	my $self = shift;

	#$nListType is set to  eLocationsList when asked for continents, countries or city listing
	if($self->{_DataType} != eLocationsList)
	{
		$self->{ErrorCode} = IDS_ERROR_GetListNotCalled;
		return -1;
	}
	else
	{
		return $self->{_LocationsList}->{LocNames}->[$self->{_LocationsList}->{nCurrItem}];
	}
}

#moves to next element in the list
sub NextElement
{
	my $self = shift;

	#$nListType is set to  eLocationsList when asked for continents, countries or city listing
	if($self->{_DataType} != eLocationsList)
	{
		$self->{ErrorCode} = IDS_ERROR_GetListNotCalled;
		return -1;
	}
	else
	{
		if($self->{_LocationsList}->{nCurrItem} >= $#{$self->{_LocationsList}->{LocNames}})
		{
			return -1;				
		}
		elsif($self->{_LocationsList}->{nCurrItem} < $#{$self->{_LocationsList}->{LocNames}})
		{
			$self->{_LocationsList}->{nCurrItem}++;
			return 0;
		}
	}
}

#sends HTTP query to obtain prayer times for the required city and saves the
#results in run time structure
sub GetPrayerTimes
{
	my ($self, $CityID) = @_;

	my($nListType, $document, $remote, $StartData, $aline);
	$nListType = eNoData;

	#implementing error when GetPrayerTimes called before making a call to Open function
	unless (host ne "")
	{
		$self->{ErrorCode} = IDS_ERROR_OpenNotCalled;
	}
	
	$document = "/cgi-bin/PMCalc.cgi?F=X&I=" . $self->{ClientID} . "&R=";
	
	#Get the required list if Open function called before calling it
	if($self->{ErrorCode} != IDS_ERROR_OpenNotCalled)
	{
		#store parameters received to functions local variables
	
		#document is query string that will be passed to host
		$document = $document . "GD&CT=";
		$document = $document . $CityID;

		#establish the connection to the host
		$remote = IO::Socket::INET->new( Proto     => "tcp",
						 PeerAddr  => host,
						 PeerPort  => "http(80)",
					       );

		#report an error if connection to host is not established
		unless($remote)
		{ 
			die "cannot connect to http daemon on host ". host;
		}

		print $remote "GET $document HTTP/1.0" . BLANK;

		$StartData = 0;

		#while remote is returning cetain text
		while(($StartData < 1) && (defined ($aline = <$remote>)))
		{
			#print " > " . $aline . "\n";
			#check if line is a blank line, after which the XML document follows
			if($aline eq "\r\n")
			{
				$StartData = 1;
			}
		}
		
		#make a call to function that will write response returned by host to file
		#file will be parsed by XML parser and desired information will be stored in class member variables
		ParseXMLFile($self, $remote, ePrayerTimings);

		#close the connection established to host
		close $remote;
			
	#print "   *** GetPrayerTimes ErrorCode: " . $self->{ErrorCode} . " ErrorText: " . $self->{ErrorText} . "<BR>\n";

#		if($self->{_DataType} == ePrayerTimings)
#		{
			#discard previously set errors
			#Error Code IDS_ERROR_GetListNotCalled "Call GetList function first";
			#Error Code IDS_ERROR_GetPrayerTimesNotCalled "Call GetPrayerTimes function first";
			#Error Code IDS_ERROR_EmptyList "Empty List";
#			$self->{ErrorCode} = IDS_NO_Error
#				if($self->{ErrorCode} == IDS_ERROR_GetListNotCalled || $self->{ErrorCode} == IDS_ERROR_GetPrayerTimesNotCalled || 
#					$self->{ErrorCode} == IDS_ERROR_EmptyList);
#		}

		#check whether some string is returned by host
#		if($self->{_DataType} != ePrayerTimings)
#		{
#			$self->{ErrorCode} = IDS_ERROR_EmptyString
#				if($self->{ErrorCode}) == IDS_NO_Error;
#		}
		#discard error that was set that empty string returned by host
#		elsif($self->{ErrorCode} == IDS_ERROR_EmptyString)
#		{
#			$self->{ErrorCode} = IDS_NO_Error;
#		}
	}
}

#functions that will be called when asked for prayer timings
#returns parent element(Country's ID) to which this city belongs
sub GetCountryID
{
	my $self = shift;

	#$nListType is set to ePrayerTimings when asked for prayer timings
	if($self->{_DataType} != ePrayerTimings)
	{
		$self->{ErrorCode} = IDS_ERROR_GetPrayerTimesNotCalled;
		return -1;
	}
	else
	{
		return $self->{_TimesData}->{nCountryID};
	}
}

#returns ID of the city
sub CityID
{
	my $self = shift;

	#$nListType is set to ePrayerTimings when asked for prayer timings
	if($self->{_DataType} != ePrayerTimings)
	{
		$self->{ErrorCode} = IDS_ERROR_GetPrayerTimesNotCalled;
		return -1;
	}
	else
	{
		return $self->{_TimesData}->{nCityID};
	}
}

#returns Title of the city
sub CityTitle
{
	my $self = shift;

	#$nListType is set to ePrayerTimings when asked for prayer timings
	if($self->{_DataType} != ePrayerTimings)
	{
		$self->{ErrorCode} = IDS_ERROR_GetPrayerTimesNotCalled;
		return -1;
	}
	else
	{
		return $self->{_TimesData}->{sCityTitle};
	}
}

#returns time zone of the city
sub CityTimeZone
{
	my $self = shift;

	#$nListType is set to ePrayerTimings when asked for prayer timings
	if($self->{_DataType} != ePrayerTimings)
	{
		$self->{ErrorCode} = IDS_ERROR_GetPrayerTimesNotCalled;
		return -1;
	}
	else
	{
		return $self->{_TimesData}->{sCityTimeZone};
	}
}

#returns Islamic date for city
sub CityIslamicDate
{
	my $self = shift;

	#$nListType is set to ePrayerTimings when asked for prayer timings
	if($self->{_DataType} != ePrayerTimings)
	{
		$self->{ErrorCode} = IDS_ERROR_GetPrayerTimesNotCalled;
		return -1;
	}
	else
	{
		return $self->{_TimesData}->{sCityIslamicDate};
	}
}

#returns Gregorian date for city
sub CityGregorianDate
{
	my $self = shift;

	#$nListType is set to ePrayerTimings when asked for prayer timings
	if($self->{_DataType} != ePrayerTimings)
	{
		$self->{ErrorCode} = IDS_ERROR_GetPrayerTimesNotCalled;
		return -1;
	}
	else
	{
		return $self->{_TimesData}->{sCityGregorianDate};
	}
}

#returns default/official Asr Fiqh for city
sub CityAsrFiqh
{
	my $self = shift;

	#$nListType is set to ePrayerTimings when asked for prayer timings
	if($self->{_DataType} != ePrayerTimings)
	{
		$self->{ErrorCode} = IDS_ERROR_GetPrayerTimesNotCalled;
		return -1;
	}
	else
	{
		return $self->{_TimesData}->{sCityAsrFiqh};
	}
}

#returns requested prayer time for city
sub CityPrayerTime
{
	my ($self, $PrayerName) = @_;

	#$nListType is set to ePrayerTimings when asked for prayer timings
	if($self->{_DataType} != ePrayerTimings)
	{
		$self->{ErrorCode} = IDS_ERROR_GetPrayerTimesNotCalled;
		return -1;
	}
	else
	{
		return $self->{_TimesData}->{CityPrayerTimes}->{$PrayerName};
	}
}

#returns 0 for no error and non zero error code for error
sub GetError
{
	my $self = shift;
	return $self->{ErrorCode};
}

#returns error string if error function will return non zero
sub GetErrorText
{
	my $self = shift;
	my $err = $self->{ErrorCode};
	if(($err >= IDS_NO_Error) && ($err <= IDS_ERROR_EmptyList))
	{
		return $PMErrors[$err];
	}
	else
	{
		if(defined($self->{ErrorText}))
		{
			return $self->{ErrorText}
		}
		else
		{
			return "Error text not received from server.";
		}
	}
}

#Function that will parse XML file
sub ParseXMLFile
{
	#access arguments passed
	my ($self, $xmlstream, $List) = @_;
	
	#discard all element names previously stored in an array
	$#{$self->{_LocationsList}->{LocNames}} = -1;
			
	#discard all element IDs previously stored in an array
	$#{$self->{_LocationsList}->{LocIDs}} = -1;
	$self->{_LocationsList}->{nCurrItem} = 0;

	#declare parser object
	my $Parser = new XML::Parser(Style=>'Stream');

	#variable that will hold the text appearing within start and end tag that is country name
	#my ($csText);
	
	$Parser->{PMText} = '';
	$Parser->{PMListType} = $List;
	$Parser->{PMObj} = $self;

	#socket having response from the server
	$Parser->parse($xmlstream);
		
	$self->{_LocationsList}->{nCurrItem} = 0;

	#Parser calls StartTag sub when it reads opening tag from XML file
	sub StartTag
	{
		#first argument is reference to parser object and second is string containing element type name
		my ($expat,$elementtype) = @_;
		
	   #print " -- StartTag: elementtype = " . $elementtype . "<br>\n";
		if($elementtype eq "PMxml")
		{
			my $datatype = %_->{datatype};
		   #print " -- StartTag: datatype = " . $datatype . "<br>\n";
			if($datatype eq "Error")
				{ $expat->{PMObj}->{_DataType} = eNoData; }
			elsif($datatype eq "Errors")
				{ $expat->{PMObj}->{_DataType} = eNoData; }
			elsif($datatype eq "PrayerTimes")
				{ $expat->{PMObj}->{_DataType} = ePrayerTimings; }
			else
				{ $expat->{PMObj}->{_DataType} = eLocationsList; }
		}
	}
	
	#Parser calls Text sub when it sees characters. $_ contains text up to next tag, end tag, 
	# processing instruction, or comment
	sub Text
	{
		my($expat) = @_;

	   #print " -- expat = $expat, text= " . $_ . "<br>\n";
		#translate new line to single space
		tr/\n/ /;
		#discard all leading white space characters
		s/^\s+//;
		#discard all trailing white space characters
		s/\s+$//;

		#return empty string if nothing found as text
		return	if $_  eq "";

		#if there is found some text within start and end tag then store it to $parabuf
		$expat->{PMText} = $_;
	   #print "text= " . $_ . "<br>\n";
	}
	
	#Parser calls EndTag sub when it reads end tag from XML file
	sub EndTag
	{
		#first argument is reference to parser object and second is string containing element type name
		my ($expat,$elementtype) = @_;
		my $self = $expat->{PMObj};
	    my $nX = $self->{_LocationsList}->{nCurrItem};

	   #print " -- End: index = " . $nX . ", element type = " . $elementtype . ", value =" . $expat->{PMText} . "<br>\n";
	   #print " > EndTag: DataType = " . $self->{_DataType} . "<BR>\n";

		#get name and ID from XML file when asked for continents, countries or cities listing
		if($self->{_DataType} == eLocationsList)
		{
			if ($elementtype eq "LocID")
			{
				#Storing element ID accessed, to an array
				$self->{_LocationsList}->{LocIDs}->[$nX] = $expat->{PMText};
			}
			if ($elementtype eq "Name")
			{
				#Storing name accessed, to an array
				$self->{_LocationsList}->{LocNames}->[$nX] = $expat->{PMText};
				$self->{_LocationsList}->{nCurrItem} = $nX + 1;
			}
		}
		#asked for prayer times
		elsif($self->{_DataType} == ePrayerTimings)
		{
			#get city local id
		 	if ($elementtype eq "LocID")
		  	{
		 		$self->{_TimesData}->{nCityID} = $expat->{PMText};
		  	}
		  	#get city title
		  	if ($elementtype eq "LocTitle")
			{
				$self->{_TimesData}->{sCityTitle} = $expat->{PMText};
		  	}
		  	#get Country ID
		  	if ($elementtype eq "CountryID")
			{
				$self->{_TimesData}->{nCountryID} = $expat->{PMText};
		  	}
		  	#get State ID
		  	if ($elementtype eq "StateID")
			{
				$self->{_TimesData}->{nStateID} = $expat->{PMText};
		  	}
		  	#get city title
		  	if ($elementtype eq "LocTitle")
			{
				$self->{_TimesData}->{sCityTitle} = $expat->{PMText};
		  	}
		  	#get city time zone
		  	if ($elementtype eq "LocTimeZone")
			{
				$self->{_TimesData}->{sCityTimeZone} = $expat->{PMText};
			}
			#get city islamic date
			if ($elementtype eq "IDate")
			{
				$self->{_TimesData}->{sCityIslamicDate} = $expat->{PMText};
		  	}
		  	#get city gregorian date
		  	if ($elementtype eq "GDate")
			{
				$self->{_TimesData}->{sCityGregorianDate} = $expat->{PMText};
			}
			#get city As Fiqh
			if ($elementtype eq "AsrFiqh")
			{
				$self->{_TimesData}->{sCityAsrFiqh} = $expat->{PMText};
			}
			#get fajr timing
			if ($elementtype eq "Fajr")
			{
				$self->{_TimesData}->{CityPrayerTimes}->{$elementtype} = $expat->{PMText};
			}
			#get Shurooq timing
			if ($elementtype eq "Shurooq")
			{
				$self->{_TimesData}->{CityPrayerTimes}->{$elementtype} = $expat->{PMText};
		  	}
		  	#get Zuhr timing
		  	if ($elementtype eq "Zuhr")
			{
				$self->{_TimesData}->{CityPrayerTimes}->{$elementtype} = $expat->{PMText};
			}
			#get AsrHanafi timing
		  	if ($elementtype eq "AsrHanafi")
			{
				$self->{_TimesData}->{CityPrayerTimes}->{$elementtype} = $expat->{PMText};
			}
			#get AsrShafei timing
		 	if ($elementtype eq "AsrShafei")
			{
				$self->{_TimesData}->{CityPrayerTimes}->{$elementtype} = $expat->{PMText};
			}
			#get Maghrib timing
		  	if ($elementtype eq "Maghrib")
			{
				$self->{_TimesData}->{CityPrayerTimes}->{$elementtype} = $expat->{PMText};
		 	}
		 	#get Isha timing
		  	if ($elementtype eq "Isha")
			{
				$self->{_TimesData}->{CityPrayerTimes}->{$elementtype} = $expat->{PMText};
		  	}
		}
		else
		{
		 	#get error code
		  	if ($elementtype eq "ErrorCode")
			{
				$self->{ErrorCode} = $expat->{PMText};
				$self->{ErrorCode} += 500 if $self->{ErrorCode} < 500;
		  	}
			#get error text
		  	if ($elementtype eq "ErrorText")
			{
				$self->{ErrorText} = $expat->{PMText};
		  	}
		}
		$expat->{PMText} = '';
	}		
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Religion::Islam::PrayMind - a Perl module that is a client for PrayerMinder server

=head1 SYNOPSIS

  use Religion::Islam::PrayMind;

  
  $p1 = new PMConnect(ClientID => "xxxx");
  #where xxxx is the client web site's ID at the PrayerMinder server.

  $p1->GetList(<listtype> [, <parentID>);
  $p1->GetPrayerTimes(<cityID>);

=head1 DESCRIPTION

This module provides ways to obtain data from the PrayerMinder server.
It is built on top of L<XML::Parser>. Each call to L<GetList> or L<GetPrayerTimes>
methods opens a socket connection to the PrayerMinder server,
and creates a new instance of XML::Parser which is then used to parse the
data received through the socket.

B<Example>


The following files show example usage of the PrayMind module:

=over 4

=item - ContinentsList.pl

=item - CountriesList.pl

=item - CitiesList.pl

=item - CityTimes.pl

=back

=head2 EXPORT


Exported constants and variables

=over 4

=item * Version of the module.

=over 4

=item . $VERSION 

=back

=item * LIST_TYPE

=over 4

=item . eContinentsList

=item . eCountriesList

=item . eStatesList

=item . eCitiesListForState

=item . eCitiesListForCountry 

=item . ePrayerTimes

=item . ePrayerTimeTable

=back

=item * Error_ID

=over 4	

=item . IDS_NO_Error

=item . IDS_ERROR_OpenNotCalled

=item . IDS_ERROR_ClientIDNotSpecified

=item . IDS_ERROR_EmptyString

=item . IDS_ERROR_GetListNotCalled

=item . IDS_ERROR_GetPrayerTimesNotCalled

=item . IDS_ERROR_EmptyList

=back

=back

=head1 METHODS

=over 4

=item new(ClientID => "CLIENTID")

This is a class method, the constructor for PMConnect. Client ID for
the caller's PrayerMinder account is passed as keyword value pair.


=item GetList(LIST_TYPE [, PARENT_ID])

This method retrieves a list of locations.

B<PARAMETERS>

=over 4

=item * LIST_TYPE

Specifies type of list desired. The properties and
elementes of the list can be retrieved using relevant methods 
listed later. L<GetError>  and L<GetErrorText> must be called
before calling any other methods to make sure no errors
occurred.  Possible values for LIST_TYPE are listed below:

=over 4

=item . eContinentsList

=item . eCountriesList

=item . eStatesList (not yet implemented)

=item . eCitiesListForState (not yet implemented)

=item . eCitiesListForCountry

=item . eCitiesSearchList (not yet implemented)

=back

=item * PARENT_ID

Not needed if LIST_TYPE is I<eContinentsList>, required otherwise.
Specifies the parent whose children are to be listed.

=back

=item GetListSize

B<Returns> integer


Called after L<GetList> to obtain the number of locations in the list.

=item GetElementID

B<Returns> integer


Called after L<GetList> to obtain the number of locations in the list.

=item GetElementName

B<Returns> string


Called after L<GetList> to obtain the number of locations in the list.

=item NextElement

B<Returns> I<true> if successful, I<false> for no more elements.


Called after L<GetList> to obtain the number of locations in the list.


=item GetPrayerTimes(CITY_ID)

This method retrieves prayer times for the requested city. CITY_ID specifies
the ID of the city requested. L<GetError>  and L<GetErrorText> must be called
before calling any other methods to make sure no errors
occurred.

=item CityID

B<Returns> integer


Called after L<GetPrayerTimes> to obtain the ID for the city.

=item CityTitle

B<Returns> string


Called after L<GetPrayerTimes> to obtain the title for the city.

=item CityTimeZone

B<Returns> string (floating point decimal number)


Called after L<GetPrayerTimes> to obtain the time zone for the city.

=item CityIslamicDate

B<Returns> string


Called after L<GetPrayerTimes> to obtain today's Islamic date for the city.

=item CityGregorianDate

B<Returns> string


Called after L<GetPrayerTimes> to obtain today's Gregorian date for the city.

=item CityAsrFiqh

B<Returns> string


Called after L<GetPrayerTimes> to obtain the default Asr fiqh method  for
the city.

=item CityPrayerTime(PRAYER_NAME)

B<Returns> string


Called after L<GetPrayerTimes> to obtain the requested prayer time for the city.

B<PARAMETERS>

=over 4

=item * PRAYER_NAME

Specifies prayer whose time is desired. Possible values for PRAYER_NAME are listed below:

=over 4

=item . Fajr

=item . Shurooq

=item . Zuhr

=item . AsrHanafi

=item . AsrShafei

=item . Maghrib

=item . Isha

=back

=back

=item GetError

B<Returns> L<Error_ID>


Called after L<GetPrayerTimes> or L<GetList> to obtain the error ID. Returns
values indicates error ID or IDS_NoError if no errors occurred.

=item GetErrorText

B<Returns> string


Called after L<GetError> to obtain the text description of the last error.

=back

=head1 AUTHOR

Tasmin Ahmad, E<lt>support@prayerminder.comE<gt>

Web site: L<http://www.prayerminder.com/>

=cut
