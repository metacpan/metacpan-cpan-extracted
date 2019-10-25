#!perl -T

use Test::More tests => 14;

BEGIN {
    use_ok( 'Net::Kafka' ) || print "Bail out!\n";
}

# Create a list and add some data.
my $tp_list = Net::Kafka::TopicPartitionList->new;

# Add the same one multiple times.
$tp_list->add("my-topic1", 0);
$tp_list->add("my-topic1", 0);
$tp_list->add("my-topic1", 0);
$tp_list->add("my-topic1", 0);
$tp_list->set_offset("my-topic1", 0, -4444);
my $o = $tp_list->offset("my-topic1", 0);
ok($o == -4444, 'offset getter ok');
$tp_list->set_offset("my-topic1", 0, 4444);

$tp_list->add("my-topic1", 1);
$tp_list->set_offset("my-topic1", 1, 5555);

$tp_list->add("my-topic1", 2);
$tp_list->set_offset("my-topic1", 2, 6666);

$tp_list->add("my-topic1", 3);
$o = $tp_list->offset("my-topic1-not-there", 9999);
ok(!$o, 'offset getter of non-existant topic ok');

ok($tp_list->size() == 4, 'size of list is ok');

# Test deletion works.
$tp_list->del("my-topic1", 3);
ok($tp_list->size() == 3, 'size of list minus the deleted is ok');


my ($topic, $partition, $offset);
($topic, $partition, $offset) = $tp_list->get(0);
ok($topic eq "my-topic1", 'topic name is ok');
ok($partition == 0, 'partition 0 is ok');
ok($offset == 4444, 'offset for part 0 is ok');

($topic, $partition, $offset) = $tp_list->get(1);
ok($topic eq "my-topic1", 'topic name is ok');
ok($partition == 1, 'partition 1 is ok');
ok($offset == 5555, 'offset for part 1 is ok');

($topic, $partition, $offset) = $tp_list->get(2);
ok($topic eq "my-topic1", 'topic name is ok');
ok($partition == 2, 'partition 2 is ok');
ok($offset == 6666, 'offset for part 2 is ok');
