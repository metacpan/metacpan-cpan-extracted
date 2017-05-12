#!/usr/bin/env perl

# +--------------------------------------------------------------------------+
# | Licensed under the Apache License, Version 2.0 (the "License");          |
# | you may not use this file except in compliance with the License.         |
# | You may obtain a copy of the License at                                  |
# |                                                                          |
# |     http://www.apache.org/licenses/LICENSE-2.0                           |
# |                                                                          |
# | Unless required by applicable law or agreed to in writing, software      |
# | distributed under the License is distributed on an "AS IS" BASIS,        |
# | WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. |
# | See the License for the specific language governing permissions and      |
# | limitations under the License.                                           |
# +--------------------------------------------------------------------------+

use strict;
use warnings;

use TL1::Toolkit;

###########################################################################
# Local configuration data

my $username = "xxxx";
my $password = "xxxx";

# End of local configuration data
###########################################################################

if ($#ARGV != 0) {
	print "usage: get_alarms.pl hostname\n";
	exit;
}

my $hostname = $ARGV[0];

my $tl1 = TL1::Toolkit->new(
        hostname => $hostname,
        username => $username,
        password => $password,
        peerport => '23',
        verbose  => 0,
);

# connect and login
if ($tl1->open() == 0) {
	print STDERR "$0: Could not connect to $hostname\n";
	exit 1;
}

# retrieve alarm info
my @out = $tl1->get_alarms();
if (!defined(@out)) {
	print "$hostname, no alarms\n";
} else {
	# print results
	for my $href (@out) {
		print "$hostname, $href->{interface}, " .
			"$href->{date}, $href->{alarm}\n";
	}
}

# logout and disconnect
$tl1->close();

exit 0;
