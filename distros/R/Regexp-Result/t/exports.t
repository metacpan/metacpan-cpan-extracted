use strict;
use warnings;
use Test::More;
use Regexp::Result qw(rr);

'foo' =~ /f/;
isa_ok(rr,'Regexp::Result');

done_testing;
