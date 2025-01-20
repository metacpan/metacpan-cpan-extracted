use strict;
use warnings;
use Test2::V0;

use Music::Harmonica::TabsCreator 'tune_to_tab_rendered';

like(tune_to_tab_rendered('invalid'), qr/^Invalid syntax/);

done_testing;
