#!/usr/bin/perl -T

use Test::More tests => 1;
use Paranoid;
use Paranoid::Debug;
use Parse::PlainConfig;

use strict;
use warnings;

psecureEnv();

use lib qw(t/lib);
use BadConf;

my $obj = new BadConf;
ok( !defined $obj, 'new object - 1' );

