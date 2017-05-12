#!perl -T

use Test::More tests => 2;

use Scalar::IfDefined qw/ifdef/;

is((ifdef { $_ + 1 } 1) , 2);
is((ifdef { $_ + 1 } undef) , undef);
