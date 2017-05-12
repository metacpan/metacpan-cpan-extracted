use Test::More tests => 2;

use Osgood::Event;
use Osgood::EventList;

my $list = Osgood::EventList->new;

my $json = $list->freeze;

my $slist = Osgood::EventList->thaw($json);
isa_ok($slist, 'Osgood::EventList', 'isa Osgood::EventList');

cmp_ok($slist->size, '==', 0, 'Zero events');
