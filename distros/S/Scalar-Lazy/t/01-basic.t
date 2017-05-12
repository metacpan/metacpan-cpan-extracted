#!perl -T
#
# $Id: 01-basic.t,v 0.1 2008/06/01 16:22:31 dankogai Exp $
#

use strict;
use warnings;
use Test::More tests => 5;
use Scalar::Lazy;

my $scalar = lazy { 1 };
is $scalar, 1, 'scalar';
my $array = lazy { [ 0 .. 7 ] };
is_deeply $array, [ 0 .. 7 ], 'array';
my $hash = lazy { { one => 1, two => 2 } };
is_deeply $hash, { one => 1, two => 2 }, 'hash';
my $code = lazy { sub { 1 } };
is $code->(), 1, 'code';
my $handle = lazy { *STDIN };
is $handle, *STDIN, 'handle';
