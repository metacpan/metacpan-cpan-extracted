# -*- perl -*-
use lib 't';

use strict;
use warnings;
use Test::More tests => 2;
use POSIX::Run::Capture;

my $obj = new POSIX::Run::Capture;

is($obj->timeout, 0);

$obj->set_timeout(60);
is($obj->timeout, 60);
