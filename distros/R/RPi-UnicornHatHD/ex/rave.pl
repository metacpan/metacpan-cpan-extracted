# Example taken from synopsis
use RPi::UnicornHatHD;
my $display = RPi::UnicornHatHD->new();
while (1) { # Mini rave!
	$display->set_all(sprintf '#%06X', int rand(hex 'FFFFFF'));
	for (0 .. 100, reverse 0 .. 100) {
		$display->brightness($_ / 100);
		$display->show();
	}
}