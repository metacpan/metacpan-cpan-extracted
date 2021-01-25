use strict;
use warnings;

use IO::Async::Loop;
use Ryu::Async;

use Test::More;

my $loop = new_ok('IO::Async::Loop');
my $ryu = new_ok('Ryu::Async');
$loop->add($ryu);

my $sink = $ryu->sink(label => 'test_sink');
isa_ok($sink, 'Ryu::Sink');

my $out;
my $source = $sink->source;
$source->each(sub {$out = shift;});

$sink->emit(1);
ok($out, 'Source from sink is working correctly');

done_testing;

