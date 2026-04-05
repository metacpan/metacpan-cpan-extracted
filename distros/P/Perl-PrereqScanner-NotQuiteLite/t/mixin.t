use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

#TODO: This module is not widely used at all; just leave it for now
#EXPECTED: Exporter is not a mixin
test('base singlequotes', <<'END', {mixin => 0, Exporter => 0});
use mixin 'Exporter';
END

done_testing;
