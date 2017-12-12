# -*- perl -*-

use lib 't';

use strict;
use warnings;
use Test::More tests => 4;
use POSIX::Run::Capture;

my $obj = new POSIX::Run::Capture;

# Initial ARGV is empty
is(0+@{$obj->argv}, 0);

# Set argv
$obj->set_argv('cat', 'file1', 'file2');
is(0+@{$obj->argv}, 3);
is_deeply($obj->argv, [ 'cat', 'file1', 'file2' ]);

# Unset argv
$obj->set_argv();
is(0+@{$obj->argv}, 0);
