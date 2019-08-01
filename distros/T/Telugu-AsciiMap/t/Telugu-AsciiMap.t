use strict;
use warnings;
use utf8;

use Test::More tests => 2;
BEGIN { use_ok('Telugu::AsciiMap') };


my $map = Telugu::AsciiMap->new();
my $asciistring = $map->convert('కరీమింఘీణ');
my $telugustring = $map->deconvert($asciistring);

ok($telugustring eq 'కరీమింఘీణ');

done_testing();
