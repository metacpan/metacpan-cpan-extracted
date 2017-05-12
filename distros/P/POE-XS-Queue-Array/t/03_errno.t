#!/usr/bin/perl -w
use strict;
use Test::More tests => 2;
use Errno qw(:POSIX);

use POE::XS::Queue::Array;

$! = 0;
POE::XS::Queue::Array::_set_errno_xs(EPERM);
is($!+0, EPERM, "check errno set in .xs");
$! = 0;
POE::XS::Queue::Array::_set_errno_queue(ESRCH);
is($!+0, ESRCH, "check errno set in queue.c");
