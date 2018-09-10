#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: basic.pl
#
#        USAGE: ./basic.pl  
#
#  DESCRIPTION: Read passwords from STDIN, one per line, and check.
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      VERSION: 1.0
#      CREATED: 22/06/18 17:04:21
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use Try::Tiny;
use Password::Policy;

my $pp = Password::Policy->new (config => 'policy.yaml');
while (my $pass = <STDIN>) {
	chomp $pass;
	try {
		$pp->process({ password => $pass });
	} catch {
		if ($_->isa ("Password::Policy::Exception::PwnedError")) {
			warn "Unable to verify pwned status - try again later\n";
			return;
		}
		print "'$pass' failed checks: $_ - don't use it\n";
	};
}
