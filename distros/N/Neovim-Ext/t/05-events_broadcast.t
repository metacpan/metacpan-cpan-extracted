#!perl

use Test::More;
use lib '.', 't/';
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

$vim->subscribe ('event2');

$vim->command ('call rpcnotify(0, "event1", 1, 2, 3)');
$vim->command ('call rpcnotify(0, "event2", 4, 5, 6)');
$vim->command ('call rpcnotify(0, "event2", 7, 8, 9)');

my $event = $vim->next_message();
is $event->[1], 'event2';
is_deeply $event->[2], [4, 5, 6];

$event = $vim->next_message();
is $event->[1], 'event2';
is_deeply $event->[2], [7, 8, 9];

$vim->unsubscribe ('event2');
$vim->subscribe ('event1');

$vim->command ('call rpcnotify(0, "event2", 10, 11, 12)');
$vim->command ('call rpcnotify(0, "event1", 13, 14, 15)');

$event = $vim->next_message();
is $event->[1], 'event1';
is_deeply $event->[2], [13, 14, 15];

done_testing();
