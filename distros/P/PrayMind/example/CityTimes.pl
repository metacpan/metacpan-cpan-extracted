# CitiesList.pl
#
# Copyright (c) 2002 Tasmin Ahmad
# All rights reserved.
#
# This script shows prayer times and other data for a city.
# It retrieves prayer times using the Religion::Islam::PrayMind 
# object.
#
# This script is provided as a sample only.
# You may use this script as a starting point to implement your own
# user interface for providing prayer times from your site by
# fetching data from the prayerminder server.
#
# You will need to obtain a PrayerMinder ID before using this
# script. Please send e-mail to support@prayerminder.com to
# obtain your ID, and state the purpose for which your wish
# to use this script.
#
# This script is free software; you can redistribute it and/or modify
# it under the "Artistic License", as described in the accompanying
# License.txt file. 
#
# DISCLAIMER
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#

print "Content-type: text/html \n\n";

print "<HTML>\n";
print "<HEAD><TITLE>";
print "PrayerMinder Prayer Times Sample";
print "</TITLE></HEAD>\n";
print "<BODY>\n";

# Religion::Islam::PrayMind object will be used to get City Prayer Times
use Religion::Islam::PrayMind;
$objGetData = new Religion::Islam::PrayMind(ClientID => "0001");

$QueryString = $ENV{'QUERY_STRING'};
#retrieve continent ID and country ID and city ID from Query string
if($QueryString =~ /CN=(.*)&CT=(.*)&CY=(.*)&Continent=(.*)&Country=(.*)/)
{
	$nContinentID = $1;
	$nCountryID = $2;
	$nCityID = $3;
	$Continent = $4;
	$Country = $5;
}

#sends HTTP query to obtain prayer times for the required city and saves the
#results in run time structure
$objGetData->GetPrayerTimes($nCityID)
	unless ($objGetData->GetError != 0);

if($objGetData->GetError != 0)
{
	print "<h2>Error[" . $objGetData->GetError . "]</h2>\n";
	print "<i>" . $objGetData->GetErrorText . "</i><br>\n";
}
else
{

print "<h1>Prayer Times</h1><br>\n";

#display links to continents, countries and cities page
print "<TABLE width=50%>";
print " <TR>";
print "  <TD>\n   ";
print "<EM>";
print "<A HREF='ContinentsList.pl'>";
print "1. Continents";
print "</A>";
print "</EM>\n";
print "  </TD>\n";
print "  <TD>\n   ";
print "<EM>";
print "<A HREF='CountriesList.pl?CN=";
print "$nContinentID";
print "&Continent=";
print "$Continent";
print "'>";
print "2. Countries";
print "</A>";
print "</EM>\n";
print "  </TD>\n";
print "  <TD>\n   ";
print "<EM>";
print "<A HREF='CitiesList.pl?CN=";
print "$nContinentID";
print "&CT=";
print "$nCountryID";
print "&Continent=";
print "$Continent";
print "&Country=";
print "$Country";
print "'>";
print "3. Cities";
print "</A>";
print "</EM>\n";
print "  </TD>\n";
print "  <TD>\n   ";
print "<EM>";
print "<B>";
print "4. Prayer Times";
print "</B>";
print "</EM>\n";
print "  </TD>";
print " </TR>";
print "</TABLE>\n";
print "<BR>\n";

print "<b>";
print $objGetData->CityTitle();
print "</b><br>\n<b>";
print $objGetData->CityIslamicDate();
print "</b><br>\n<b>";
print $objGetData->CityGregorianDate();
print "</b><br>\n";
print "<br>\nTime Zone: ";
print $objGetData->CityTimeZone();
print "<br>\nDefault Asr Fiqh: ";
print $objGetData->CityAsrFiqh();
print "<br>\n";
print "<br>\n";
print "Fajr : ";
print $objGetData->CityPrayerTime(Fajr);

print "<br>\nShurooq : ";
print $objGetData->CityPrayerTime(Shurooq);

print "<br>\nZuhr : ";
print $objGetData->CityPrayerTime(Zuhr);

print "<br>\nAsrShafei : ";
print $objGetData->CityPrayerTime(AsrShafei);

print "<br>\nAsrHanafi : ";
print $objGetData->CityPrayerTime(AsrHanafi);

print "<br>\nMaghrib : ";
print $objGetData->CityPrayerTime(Maghrib);

print "<br>\nIsha : ";
print $objGetData->CityPrayerTime(Isha);

print "\n<hr>\n";
print "<p><font size=-1>";
print "<b>DISCLAIMER</b>";
print "</font></p>\n";
print "<p><font size=-1>";
print "This file is provided as a sample only.<BR>\n";
print "The author or PrayerMinder will not be responsible for \n";
print "any damage caused by this file and/or the script contained \n";
print "in it.";
print "</font></p>\n";
print "<p><font size=-1>";
print "You may use this file as a starting point to implement your own \n";
print "user interface for providing prayer times from your site by \n";
print "fetching data from the prayerminder server.";
print "</font></p>\n";
}
print "\n</BODY>\n";
print "</HTML>\n";

