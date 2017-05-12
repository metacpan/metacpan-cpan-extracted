use strict;
use warnings;
use Test::More tests => 2;

use parent qw(NativeCall);

sub strcmp :Args(string,string) :Native :Returns(int) {}
is strcmp("abc","abc"), 0;
isnt strcmp("abc","def"), 0;
