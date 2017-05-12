use strict;
use warnings;
use PDL;
use PDL::Graphics::Prima::Simple;

func_plot(0, 5, \&PDL::sin);
func_plot(0, 5, \&PDL::exp, 500);

func_plot (0, 4, sub {
	my $xs = shift;
	my $ys = exp(-$xs);
	return $ys->setbadif($xs < 0);
});

func_plot (0, 4, sub { 1 });

func_plot (0, 4, sub {
	my $xs = shift;
	my $first_ys = sin($xs);
	my $second_ys = cos($xs) + 3;
	return $first_ys->cat($second_ys);
});

