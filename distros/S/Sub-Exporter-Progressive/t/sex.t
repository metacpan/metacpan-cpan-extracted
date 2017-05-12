
use strict;
use warnings;

use Test::More;
BEGIN {
    plan skip_all => 'Sub::Exporter not installed'
        unless eval { require Sub::Exporter };
}

use lib 't/lib';
use A::Junk 'junk1' => { -as => 'junk' };

ok(main->can('junk'), 'sub renamed with Sub::Exporter');
ok($INC{'Sub/Exporter.pm'}, 'Sub::Exporter loaded');

done_testing;
