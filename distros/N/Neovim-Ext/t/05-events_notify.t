#!perl

use Test::More;
use lib '.', 't/';
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

my $cid = $vim->channel_id;

$vim->command ('let g:test = 3', async_ => 1);
$vim->command ("call rpcnotify($cid, \"test-event\", g:test)", async_ => 1);

my $event = $vim->next_message();
is $event->[1], 'test-event';
is_deeply $event->[2], [3];

done_testing();

