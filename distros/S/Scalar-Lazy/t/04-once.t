#!perl -T
#
# $Id: 04-once.t,v 1.1 2008/06/01 17:09:08 dankogai Exp dankogai $
#

use strict;
use warnings;
use Test::More tests => 4;
use Scalar::Lazy;

my $x = 0;
my $once = lazy { ++$x } 'init';
is $once, 1, 'once';
is $once, 1, 'once';
my $succ = lazy { ++$x };
isnt $succ, 1, 'succ';
is $succ, 3, 'succ';

