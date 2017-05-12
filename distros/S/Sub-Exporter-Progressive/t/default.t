
use strict;
use warnings;

use Test::More;
use lib 't/lib';
use A::Junk;

ok(main->can('junk2'), 'sub exported');
ok(! $INC{'Sub/Exporter.pm'}, 'Sub::Exporter not loaded');

done_testing;
