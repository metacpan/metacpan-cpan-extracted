#!perl

use Test::More tests => 1;

BEGIN {
	use_ok('Plack::Middleware::DetectRobots') || print "Bail out!";
}

diag(
	"Testing Plack::Middleware::DetectRobots $Plack::Middleware::DetectRobots::VERSION, Perl $], $^X"
);
