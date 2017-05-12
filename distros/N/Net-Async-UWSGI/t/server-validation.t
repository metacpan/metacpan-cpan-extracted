use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Net::Async::UWSGI::Server;
use IO::Async::Loop;
use File::Temp qw(tempdir);

my $loop = IO::Async::Loop->new;

like(exception {
	$loop->add(Net::Async::UWSGI::Server->new)
}, qr/No path/, 'missing path');
done_testing;

