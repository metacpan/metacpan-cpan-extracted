use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 5;
use Perlmazing;

my @values = ('0123456789', 'abcdefghijklmnopqrstuvwxyz', '0123456789abcdef');
is scalar md5(@values), '781e5e245d69b566979b86e28d23f2c7', 'scalar';
my @result = md5 @values;
is $result[0], '781e5e245d69b566979b86e28d23f2c7', 'array';
md5 @values;
is $values[0], '781e5e245d69b566979b86e28d23f2c7', 'void';
is $values[1], 'c3fcd3d76192e4007dfb496cca67e13b', 'void';
is $values[2], '4032af8d61035123906e58e067140cc5', 'void';
