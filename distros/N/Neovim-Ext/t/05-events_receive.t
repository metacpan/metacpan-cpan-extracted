#!perl

use Test::More;
use lib '.', 't/';
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

my $cid = $vim->channel_id;

$vim->command ("call rpcnotify($cid, \"test-event\", 1, 2, 3)");
my $event = $vim->next_message();
is $event->[1], 'test-event';
is_deeply $event->[2], [1, 2, 3];

$vim->command ("au FileType python call rpcnotify($cid, \"py!\", bufnr(\"\$\"))");
$vim->command ('set filetype=python');

$event = $vim->next_message();
is $event->[1], 'py!';
is_deeply $event->[2], [tied (@{$vim->current->buffer})->number];

done_testing();

