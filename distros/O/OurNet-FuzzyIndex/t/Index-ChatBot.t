#!/usr/bin/perl -w

use strict;
use Test;

my @test;

BEGIN {
    @test = (
	'諸行無常, 是生滅法.'
	=> '把我說得像是 XX 花系列的悲涼，我才想哭～～',

	'我愚人之心也哉!'     
	=> '沒有什麼留得住東去的一溪春光。',

	'傷靈修之數化.',      
	=> '如果你不能懂得我的逃離，那麼你也就不值得我的背叛。',

	# sort bug
	'晝嬉暮思, 飛揚寂寞.',
	=> qr/^(?:\Q這種笑法太悲哀了。\E|\Q別扭傷了頸子喲（笑）。\E)$/,
    );

    plan tests => 1 + (@test / 2);
}

use OurNet::ChatBot;

ok(my $db = OurNet::ChatBot->new('fianjmo', 'fianjmo.db', 1));

while (my($k, $v) = splice(@test, 0, 2)) {
    ok($db->input($k), $v);
}
