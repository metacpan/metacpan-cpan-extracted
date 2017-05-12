#!/usr/bin/perl -w
############################################################
#
#   $Id$
#   rrd-client-infrant.pl - Infrant ReadyNAS NV+ data gathering script for rrd-server.pl
#
#   Copyright 2007, 2008 Nicola Worthington
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
# vim:ts=4:sw=4:tw=78

use 5.6.1;
use strict;
use warnings;
use LWP::UserAgent qw();
use HTML::TokeParser qw();
use HTTP::Request::Common qw();

use constant USER   => 'admin';
use constant PASS   => 'password';
use constant REALM  => 'Control Panel';
use constant NETLOC => '192.168.0.2:443';
use constant URL    => 'https://'.NETLOC.'/admin/index.cgi?button=Current&MODIFIED=0&CURRENTPAGE=Status&CURRENTTAB=health&DEBUGLEVEL=0&command=Refresh&MODE=Advanced';
use constant RRDURL => 'http://rrd.me.uk/cgi-bin/rrd-server.cgi';

my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->credentials(NETLOC, REALM, USER, PASS);
my $response = $ua->get(URL);
die $response->status_line unless $response->is_success;

my $p = HTML::TokeParser->new(\$response->content);
my %update = ();
my $time = time;

while (my $token = $p->get_tag('tr')) {
	my $text = $p->get_trimmed_text('/tr');
	$text =~ s/[^a-zA-Z0-9\.\-\_\%\/\\]/ /g;
	if ($text =~ /\b((Disk|Fan|Temp|UPS)(?:\s+([0-9]+)\b)?.+)/) {
		my ($type,$num) = ($2,$3);
		local $_ = $1;

		if ($type eq 'Disk' || $type eq 'Temp') {
			if (/\s(([0-9\.]+)\s*C)\s/) { $update{"hdd.temp.c"}->{"${type}_${num}_C"} = $2; }
			if (/\s(([0-9\.]+)\s*F)\s/) { $update{"hdd.temp.f"}->{"${type}_${num}_F"} = $2; }
		}

		if ($type eq 'Fan' && /\s(([0-9\.]+)\s*RPM)\s/) { $update{"misc.fan.rpm"}->{"${type}_${num}_RPM"} = $2; }
	}
}


while (my ($graph,$ref) = each %update) {
	my $data = '';
	while (my ($key,$value) = each %{$ref}) {
		$data .= "$time.$graph.$key $value\n"
	}
	update($data);
}


exit;


sub update {
	my $data = shift;

	my $ua = LWP::UserAgent->new(agent => $0);
	my $resp = $ua->request(HTTP::Request::Common::POST(RRDURL,
					Content_Type => 'text/plain',
					Content => $data
				));

	if ($resp->is_success) {
		printf("%s\n",$resp->content);
	} else {
		warn 'Posting Error: '.$resp->status_line;
	}

	return $resp->is_success;
}


__END__
nicolaw@eowyn:~$ wget -q -O - --no-check-certificate --http-user=admin --http-password=password "https://192.168.0.2/admin/index.cgi?button=Current&MODIFIED=0&CURRENTPAGE=Status&CURRENTTAB=health&DEBUGLEVEL=0&command=Refresh&MODE=Advanced" | html2text -width 300 | egrep -io " (Disk|Fan|Temp|UPS) [0-9] .*"
 Disk 1   Seagate ST3500630AS 465 GB, 40C / 104F, Write-cache ON, SMART+      OK 
 Disk 2   Seagate ST3500630AS 465 GB, 41C / 105F, Write-cache ON, SMART+      OK 
 Disk 3   Seagate ST3500630AS 465 GB, 41C / 105F, Write-cache ON, SMART+      OK 
 Disk 4   Seagate ST3500630AS 465 GB, 39C / 102F, Write-cache ON, SMART+      OK 
 Fan 1    1744 RPM     [Unknown INPUT type]                                   OK 
 Temp 1   34.0C / 93F   [Normal 0-60C / 32-140F]                              OK 
 UPS 1    Not present                                                         OK 
nicolaw@eowyn:~$ 

