use strict;
use warnings;
use Test2::V0;

use Music::Harmonica::TabsCreator 'tune_to_tab';

is({ tune_to_tab('CDEFGAB') }->{richter_no_bend}, { C => [[4, -4, 5, -5, 6, -6, -7]] });
is({ tune_to_tab('B>DbEbEGbAbBb') }->{richter_no_bend}, { B => [[4, -4, 5, -5, 6, -6, -7]] });

done_testing;
