# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl OWL-Config.t'
#########################
# change 'tests => 1' to 'tests => last_test_to_print';
#use Test::More tests => 7;
use Test::More qw/no_plan/;
use strict;
use vars qw/$path/;
BEGIN {
	use FindBin qw ($Bin);
	use lib "$Bin/../lib";
	$path = $Bin;
	$path .= "/t" unless $path =~ /t$/;
	$ENV{OWL_CFG_DIR} = $path;
}

END {
	delete $ENV{OWL_CFG_DIR};
	# destroy persistent data here (if any)
}
#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
#use_ok('OWL::Config');
use OWL::Config;
my $config = OWL::Config->new();
is($config->param('generators.outdir'), 'foo', 'check for generators.outdir parameter');
is($config->param('a'), 'b', 'check for "a" parameter');
$config->delete('a');
is($config->param('a'), undef, 'check for recently deleted "a" parameter');
