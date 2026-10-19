use v5.36;
use Test::More;
use lib 'lib';
use Peta::Synth::Synth;
use Peta::Synth::Engine;

# Settings made by hand (the page, MIDI played live) held against a file's
# events: kept aside while held, the file's as of then when let go.

my $rate = 24000;
sub synth () { return Peta::Synth::Synth->new(rate => $rate, partials => 8, engine => Peta::Synth::Engine::create('perl')) }

# The file's events at their seconds from now, rendered past the last.
sub file ($s, @events) {
    $s->schedule([ map { { channel => 0, %$_ } } @events ]);
    my $until = $s->now + ($events[-1]{time} + 0.05) * $rate;
    $s->render_arrays(512) while $s->now < $until;
}
sub cc ($number, $value, $time = 0) { return { time => $time, type => 'controller', number => $number, value => $value } }
my $gm_on = { time => 0, type => 'sysex', data => "\x7e\x7f\x09\x01\xf7" };

my $s = synth();
file($s, cc(7, 80));
$s->by_hand({ type => 'controller', channel => 0, number => 7, value => 50 });
is_deeply($s->held(0), ['cc 7'], 'a volume set by hand is held');
file($s, cc(7, 110), cc(10, 20, 0.01));
is($s->channel(0)->{volume}, 50, "the file's volume kept aside");
is($s->channel(0)->{pan}, 20, 'what is not held, the file sets');
$s->let_go(0, 'cc 7');
is($s->channel(0)->{volume}, 110, "let go: the file's volume as of now");
is_deeply($s->held(0), [], 'and nothing held');

$s->by_hand({ type => 'controller', channel => 0, number => 7, value => 50 });
$s->let_go(0);
is($s->channel(0)->{volume}, 110, 'let go with nothing from the file since: as it was before');

# What is played, not set, is not held: the wheels, expression, the pedals.
$s->by_hand({ type => 'controller', channel => 0, number => $_, value => 100 }) for 1, 11, 64;
is_deeply($s->held(0), [], 'the mod wheel, expression and sustain are not held');

# The instrument: bank select and program change, held together.
$s = synth();
$s->by_hand({ type => 'controller', channel => 0, number => 0, value => 8 });
$s->by_hand({ type => 'controller', channel => 0, number => 32, value => 0 });
$s->by_hand({ type => 'program', channel => 0, program => 4 });
file($s, cc(0, 0), { time => 0.01, type => 'program', program => 40 });
is_deeply([ @{ $s->channel(0) }{qw(program variation)} ], [ 4, 8 ], "the instrument chosen by hand plays on through the file's program change");
file($s, $gm_on);
is_deeply([ @{ $s->channel(0) }{qw(program variation)} ], [ 4, 8 ], 'and through a reset');
is($s->channel(0)->{volume}, 100, 'which resets what is not held');
$s->let_go(0, 'program');
is_deeply([ @{ $s->channel(0) }{qw(program variation)} ], [ 0, 0 ], "let go: the reset's, the file's last word");

$s->by_hand({ type => 'controller', channel => 0, number => 7, value => 30 });
$s->by_hand($gm_on);
is_deeply([ $s->channel(0)->{volume}, $s->held(0) ], [ 100, [] ], 'a reset played live resets what is held too');

# A program change alone (a device): held with the bank it was chosen from.
$s = synth();
file($s, cc(0, 8));
$s->by_hand({ type => 'program', channel => 0, program => 4 });
file($s, $gm_on);
is_deeply([ @{ $s->channel(0) }{qw(program variation)} ], [ 4, 8 ], 'a program change alone keeps its bank through a reset');

# The arpeggiator: the page's settings against the file's NRPN, switches and tempo.
$s = synth();
$s->by_hand({ type => 'arp', channel => 0, name => 'mode', value => 'down' });
my $nrpn = sub ($setting, $msb, $time) { (cc(99, 0x7d, $time), cc(98, $setting, $time), cc(6, $msb, $time)) };
file($s, $nrpn->(1, 9, 0), $nrpn->(2, 2, 0.01), cc(80, 127, 0.02), { time => 0.03, type => 'tempo', usec => 500_000 * 120 / 96 });
my $arp = $s->arpeggiator(0)->params;
is($arp->{mode}, 'down', "the pattern set by hand stays through the file's NRPN");
is_deeply([ @$arp{qw(rate on tempo)} ], [ '1/8T', 1, 96 ], "the file's rate, switch and tempo, not held, apply");
$s->by_hand({ type => 'arp', channel => 0, name => 'tempo', value => 140 });
file($s, { time => 0, type => 'tempo', usec => 500_000 });
is($s->arpeggiator(0)->params->{tempo}, 140, 'a tempo set by hand stays through the file\'s');
$s->by_hand({ type => 'controller', channel => 0, number => 80, value => 0 });
file($s, cc(80, 127));
ok(!$s->arpeggiator(0)->on, 'CC 80 played live holds the switch');
is_deeply($s->held(0), [ 'arp mode', 'arp on', 'arp tempo' ], 'what the channel holds');
$s->let_go(0);
is_deeply([ @{ $s->arpeggiator(0)->params }{qw(mode on tempo)} ], [ 'pedal_up', 1, 120 ], "all let go: the file's, as of now");

# Holds are a channel's; a new file forgets them.
$s = synth();
$s->by_hand({ type => 'controller', channel => 3, number => 7, value => 30 });
file($s, cc(7, 90));
is($s->channel(0)->{volume}, 90, 'another channel takes the file\'s');
$s->forget_held;
file($s, { channel => 3, %{ cc(7, 90) } });
is($s->channel(3)->{volume}, 90, 'forgotten: the file sets it again');

done_testing;
