#!/usr/bin/perl -w
###########################################################
#
#   $Id: statlogs.pl 965 2007-03-01 19:11:23Z nicolaw $
#   statlogs.pl - Example script bundled as part of RRD::Simple
#
#   Copyright 2006 Nicola Worthington
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################

use CGI qw(header);
print header(-content_type => 'text/html');

if (opendir(DH,'/var/logs/httpd')) {
	for (sort grep(/(combined|access|error)/,readdir(DH))) {
		printf("%s %s %s <br>\n", $_, (stat("/var/logs/httpd/$_"))[7,9]);
	}
}

