use strict;
use warnings;
use Test::More;
use Test::Output;
plan(tests => 5);
use lib qw(../lib lib);
use PSGI::Hector::Log;

my $logger = PSGI::Hector::Log->new();

isa_ok($logger, 'PSGI::Hector::Log');

stderr_is {
	$logger->log('message');
} " - message\n", "Without severity";

stderr_is {
	$logger->log('message', 'info');
} "INFO - message\n", "With info severity";

stderr_is {
	$logger->log('message', 'debug');
} "", "With debug severity without debug mode";

$logger->{'__debug'} = 1;

stderr_is {
	$logger->log('message', 'debug');
} "DEBUG - message\n", "With debug severity with debug mode";
