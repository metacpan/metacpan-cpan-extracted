use strict;
use warnings;

use Env qw($RELEASE_TESTING);
use Test::More;

eval { require Test::Kwalitee::Extra; };

my $reason;

if ($@) {
	$reason = 'Test::Kwalitee::Extra not installed';
} elsif ($RELEASE_TESTING) {    
	#prereq_matches_use fails for App::Prove for some reason
	Test::Kwalitee::Extra->import(qw(!prereq_matches_use));     
} else {
	$reason = 'tests for release testing, enable using RELEASE_TESTING';
}

if ($reason) {
	plan( skip_all => $reason );
}

