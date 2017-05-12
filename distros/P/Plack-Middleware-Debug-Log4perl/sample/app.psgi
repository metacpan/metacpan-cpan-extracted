#!/usr/bin/perl

use strict;
use warnings;

use lib './lib';

use Plack;
use Plack::Builder;
use Plack::Middleware::Debug::Log4perl;

my $app = sub {
	my $logger = Log::Log4perl->get_logger('sample.app');
	$logger->info("Starting Up");
	for my $i (1..10) {
		$logger->debug("Testing .... ($i)");
	}
	$logger->info("All done here - thanks for vising");
    return [
        200, [ 'Content-Type' => 'text/html' ],
        ['<body>Hello World</body>']
    ];
};

$app = builder {
    enable 'Debug', panels =>[qw/Response Memory Timer Log4perl/];
	enable 'Log4perl', category => 'plack', conf => 'sample/log4perl.conf';
    $app;
};
