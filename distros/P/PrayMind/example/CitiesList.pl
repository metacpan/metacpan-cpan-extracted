# CitiesList.pl
#
# Copyright (c) 2002 Tasmin Ahmad
# All rights reserved.
#
# This script lists cities for a country such that each city name is 
# a link to City Prayer Times page for that City.
# It retrieves the list using the Religion::Islam::PrayMind 
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
print "PrayerMinder - Cities List";
print "</TITLE></HEAD>\n";
print "<BODY>\n";

# Religion::Islam::PrayMind object will be used to get Cities List
use Religion::Islam::PrayMind;
$objGetData = new Religion::Islam::PrayMind(ClientID => "0001");

$QueryString = $ENV{'QUERY_STRING'};
#retrieve continent ID, country ID, continent name and country name from Query string
if($QueryString =~ /CN=(.*)&CT=(.*)&Continent=(.*)&Country=(.*)/)
{
	$nContinentID = $1;
	$nCityID = $2;
	$Continent = $3;
	$Country = $4;
}


#GetList sends HTTP query to obtain the list required and saves the result
#in run-time structures.
$objGetData->GetList(eCitiesListForCountry, $nCityID)
	unless ($objGetData->GetError != 0);

if($objGetData->GetError != 0)
{
	print "<h2>Error[" . $objGetData->GetError . "]</h2>\n";
	print "<i>" . $objGetData->GetErrorText . "</i><br>\n";
}
else
{
print "<h1>Cities</h1><br>";

#display links to continents, countries and cities page
print "<TABLE width=50%>\n";
print " <TR>\n";
print "  <TD>   \n";
print "<EM>";
print "<A HREF='ContinentsList.pl'>";
print "1. Continents";
print "</A>";
print "</EM>\n";
print "  </TD>\n";
print "  <TD>\n   ";
print "<EM>";
print "<A HREF='CountriesList.pl?CN=";
print $nContinentID;
print "&Continent=";
print $Continent;
print "'>";
print "2. Countries";
print "</A>";
print "</EM>\n";
print "  </TD>";
print "  <TD>\n   ";
print "<EM>";
print "<B>";
print "3. Cities";
print "</B>";
print "</EM>\n";
print "  </TD>";
print "  <TD>\n   ";
print "<EM>";
print "4. Prayer Times";
print "</EM>\n";
print "  </TD>\n";
print " </TR>\n";
print "</TABLE>\n";
print "<BR>\n";

print "<B>";
print "Country : ";
#in the query string country name is passed in which any space appearing in it is replaced by %20
#so replacing it with space
$Country =~ s/%20/ /;
print $Country;
print "</B>\n";
print "<BR>\n";
print "Please click on a city to view its prayer times:\n";
print "<BR>\n";

#Get all cities names with each city name a link to City Prayer Times page
for($i = 1; $i <= $objGetData->GetListSize; $i++)
{
	print "<A href='CityTimes.pl?CN=";
	print "$nContinentID";
	print "&CT=";
	print "$nCityID";
	print "&CY=";
	print $objGetData->GetElementID;
	print "&Continent=";
	print $Continent;
	print "&Country=";
	print $Country;
	print "'>";
	print $objGetData->GetElementName;
	print "</A>";
	print "<BR>\n";

	$objGetData->NextElement;
}

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
print "</BODY>\n";
print "</HTML>\n";
