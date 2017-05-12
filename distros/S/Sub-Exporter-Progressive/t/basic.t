
use strict;
use warnings;

use Test::More;
use lib 't/lib';
use A::Junk 'junk1';

ok(main->can('junk1'), 'requested sub exported');
ok(! $INC{'Sub/Exporter.pm'}, 'Sub::Exporter not loaded');

done_testing;
