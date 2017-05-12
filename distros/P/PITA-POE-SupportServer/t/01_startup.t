#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;

BEGIN {
	use_ok( 'PITA::POE::SupportServer' ); # 1
};


my $server = PITA::POE::SupportServer->new(
    execute => [
        sub { sleep 60; },
    ],
    http_local_addr => '127.0.0.1',
    http_local_port => 0,
    http_startup_timeout => 10,
    http_mirrors => { '/cpan', '.' },
);

ok( 1, 'Server created' ); # 2

$server->prepare() or die $server->{errstr};

ok( 1, 'Server prepared' ); # 3

$server->run();

ok( $server->{exitcode}, 'Server ran and timed out' ); # 4

exit(0);
