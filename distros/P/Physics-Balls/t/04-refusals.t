#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;

use Physics::Balls;
use Presets;

plan tests => 14;

my $world = Presets::world_built('pool');
my @layout = ([0, 63500, 63500], [1, 190500, 63500]);

sub refused {
	my ($code, $label, %shot) = @_;
	my $layout = delete $shot{layout} || \@layout;
	my $out = Physics::Balls->strike($world, layout => $layout, ball => 0, dx => 1_000_000, dy => 0, power => 500, sx => 0, sy => 0, %shot);
	ok $out->error && $out->code eq $code && $out->$code, "$label is refused as $code"
		or diag($out->error ? $out->code . ': ' . $out->message : 'accepted');
}

refused('bad_direction', 'a zero direction', dx => 0, dy => 0);
refused('bad_direction', 'a direction over a million', dx => 1_000_001, dy => 0);
refused('bad_direction', 'a fractional direction', dx => 0.5, dy => 1);
refused('bad_power', 'power over 1000', power => 1001);
refused('bad_power', 'negative power', power => -1);
refused('bad_spin', 'a tip offset over half a radius', sx => 501, sy => 0);
refused('bad_spin', 'a fractional tip offset', sx => 0, sy => 12.5);
refused('no_ball', 'a ball not in the layout', ball => 7);
refused('bad_layout', 'a layout that is not an array', layout => 'nope');
refused('bad_layout', 'a duplicated id', layout => [ [0, 63500, 63500], [0, 190500, 63500] ]);
refused('bad_layout', 'a fractional position', layout => [ [0, 63500.5, 63500], [1, 190500, 63500] ]);
refused('overlap', 'two balls closer than a diameter', layout => [ [0, 63500, 63500], [1, 63500 + 5000, 63500] ]);

my $ok = Physics::Balls->strike($world, layout => \@layout, ball => 0, dx => 1_000_000, dy => 0, power => 500, sx => 0, sy => 0);
ok !$ok->error && $ok->isa('Physics::Balls::Outcome'), 'and a good shot plays';

my $msg = Physics::Balls::Error->of('bad_power', 'got 1200')->message;
like $msg, qr/^power must be an integer from 0 to 1000: got 1200$/, 'an error reads as a sentence with its detail';
