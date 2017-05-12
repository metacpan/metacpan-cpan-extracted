use Test::More tests => 5;

BEGIN { use_ok('Osgood::EventList'); }

use Osgood::Event;

my $list = Osgood::EventList->new;
isa_ok($list, 'Osgood::EventList', 'isa Osgood::EventList');

cmp_ok($list->size, '==', 0, 'No events in list');

my $event = Osgood::Event->new(object => 'Test', action => 'create');
$list->add_to_events($event);
cmp_ok($list->size, '==', 1, '1 event in list');

my $iterator = $list->iterator;

my $count = 0;
while($iterator->has_next) {
	$iterator->next;
	$count++;
}
cmp_ok($count, '==', 1, '1 items in iterator');
