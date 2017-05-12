
use strict;
use warnings;

use Test::More;
use lib 't/lib';
use A::JunkAll;

ok(main->can('junk1'), 'sub exported');
ok(main->can('junk2'), 'sub exported');
ok(! $INC{'Sub/Exporter.pm'}, 'Sub::Exporter not loaded');

package Other;
use Test::More;
use A::JunkAll ':all';

ok(main->can('junk1'), 'sub exported');
ok(main->can('junk2'), 'sub exported');
ok(! $INC{'Sub/Exporter.pm'}, 'Sub::Exporter not loaded');

done_testing;
