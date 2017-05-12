# -*- perl -*-

# t/003_synop.t - check to see if the synopsis sections of pod documentation actually evaluate

use Games::Roguelike::Utils qw(:all);
use Games::Roguelike::World;
use Games::Roguelike::Area;

use Test::More tests => 3;

# override console to "dump"
$Games::Roguelike::Console::DUMPFILE = ($^O=~/win32/i) ? 'NUL' : '/dev/null';
$Games::Roguelike::Console::DUMPKEYS = 'qY';

testsynop('Games::Roguelike::World');
testsynop('Games::Roguelike::Area');
testsynop('Games::Roguelike::Utils');

sub testsynop {

	my $mod = my $exp = shift;
	$exp =~ s|::|\[:\\/\\\\\]\+|g;
	$exp =~ s|$|\(\\\.pm\)\?\$|g;

	my $file;

	for (keys(%INC)) {
		$file = $INC{$_} if /$exp/;
	}

	if (!$file) {
		diag("can't find $mod file");
		return 0; 
	}

	undef $!;
	if (!open(IN, $file)) {
		return 0; 
	}

	while(<IN>) {
		last if /^=head1 SYNOPSIS/;
	}
	while(<IN>) {
		last if /^=[a-z]+/;
		next unless /^\s/;
		$synop .= $_;
	}
	close IN;
	
	if (!$synop) {
		diag("extract synopsis from '$file' failed");
		return 0; 
	}
	
	$synop .= "\n1;";

	$ok = eval($synop);

	ok($ok, "$mod synopsis");
}

