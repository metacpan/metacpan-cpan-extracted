#!/usr/bin/perl -T

use Test::More tests => 2;
use Paranoid;
use Paranoid::Debug;
use Parse::PlainConfig;

use strict;
use warnings;

psecureEnv();

use lib qw(t/lib);
use MyConf2;

#PDEBUG = 20;
my $obj = new MyConf2;
ok( defined $obj,         'new object - 1' );
ok( length $obj->default, 'conf default - 1' );

