use Test::More tests => 4;

BEGIN { use_ok('Osgood::EventList'); }

use Osgood::Event;

my $list = Osgood::EventList->new;
isa_ok($list, 'Osgood::EventList', 'isa Osgood::EventList');

$list->add_to_events(Osgood::Event->new(object => 'Test', action => 'create', id => 14));
$list->add_to_events(Osgood::Event->new(object => 'Test', action => 'create', id => 89));
$list->add_to_events(Osgood::Event->new(object => 'Test', action => 'create', id => 5));
$list->add_to_events(Osgood::Event->new(object => 'Test', action => 'create', id => 8));
cmp_ok($list->size, '==', 4, '1 event in list');
cmp_ok($list->get_highest_id, '==', 89, 'Highest Id');
