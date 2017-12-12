# -*- perl -*-

use lib 't';

use strict;
use warnings;
use Test::More tests => 3;
use POSIX::Run::Capture;

my $obj = new POSIX::Run::Capture(argv => [qw(dir /tmp)],
				  program => '/bin/ls',
				  timeout => 15);

is_deeply($obj->argv,  [qw(dir /tmp)]);
is($obj->program, '/bin/ls');
is($obj->timeout, 15);
