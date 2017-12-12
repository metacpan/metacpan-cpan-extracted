# -*- perl -*-
use lib 't';

use strict;
use warnings;
use Test::More tests => 6;
use POSIX::Run::Capture;

my $obj = new POSIX::Run::Capture;

# Initial prog is undefined
is($obj->program, undef);

# Set program
$obj->set_program('ls');
is($obj->program, 'ls');

# Unset program
$obj->set_program(undef);
is($obj->program, undef);

# Set argv array. Now, program is argv[0].
$obj->set_argv('dir');
is($obj->program, 'dir');

# Set it explicitly
$obj->set_program('ls');
is($obj->program, 'ls');
is($obj->argv->[0], 'dir');
