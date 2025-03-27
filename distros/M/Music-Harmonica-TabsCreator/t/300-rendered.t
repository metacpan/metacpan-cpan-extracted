use strict;
use warnings;
use Test2::V0;

use Music::Harmonica::TabsCreator 'tune_to_tab_rendered';

like(tune_to_tab_rendered('invalid'), qr/^Invalid syntax/);
like(tune_to_tab_rendered("A B C D E F G\n\n\n"), qr/\V\v\v\z/, '1 empty line at the end exactly');
like(tune_to_tab_rendered("# only comment\n"), qr/^No melody found/, 'only comment');

done_testing;
