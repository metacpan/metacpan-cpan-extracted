# ContinentsList.pl
#
# Copyright (c) 2002 Tasmin Ahmad
# All rights reserved.
#
# This script list continents such that each continent name 
# is a link to Countries List page for that continent.
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
print "PrayerMinder - Continents List";
print "</TITLE></HEAD>\n";
print "<BODY>\n";

# Religion::Islam::PrayMind object will be used to get Continents List
use Religion::Islam::PrayMind;

$objGetData = new Religion::Islam::PrayMind(ClientID => "0001");

#sends HTTP query to obtain the list required and saves the result in run time structure
$objGetData->GetList(eContinentsList, 0)
	unless ($objGetData->GetError != 0);

if($objGetData->GetError != 0)
{
	print "<h2>Error[" . $objGetData->GetError . "]</h2>\n";
	print "<i>" . $objGetData->GetErrorText . "</i><br>\n";
}
else
{
print "<h1>Continents</h1><br>\n";

#display links to continents, countries and cities page
print "<TABLE width=50%>\n";
print " <TR>\n";
print "  <TD>\n   ";
print "<B>";
print "<EM>";
print "1. Continents";
print "</EM>";
print "</B>\n";
print "  </TD>\n";
print "  <TD>\n   ";
print "<EM>";
print "2. Countries";
print "</EM>\n";
print "  </TD>";
print "  <TD>\n   ";
print "<EM>";
print "3. Cities";
print "</EM>\n";
print "  </TD>\n";
print "  <TD>\n   ";
print "<EM>";
print "4. Prayer Times";
print "</EM>\n";
print "  </TD>\n";
print " </TR>\n";
print "</TABLE>\n";
print "<BR>\n";

print "Please click on a continent to view its list of countries:\n";
print "<BR>\n";

#get all continent names with each continent name link to countries list page
for($n = 1; $n <= $objGetData->GetListSize; $n++)
{
	print "<A href='CountriesList.pl?CN=";
	print $objGetData->GetElementID;
	print "&Continent=";
	print $objGetData->GetElementName;
	print "'>";	
	print $objGetData->GetElementName;
	print "</A>";
	print "<BR>\n";
	$objGetData->NextElement;
}
$n = $n - 1;
print "Listed "; print $n; print " Continent(s)";
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
