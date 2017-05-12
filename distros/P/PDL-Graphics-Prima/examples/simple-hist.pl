use strict;
use warnings;
use PDL;
use PDL::Graphics::Prima::Simple;

my $data = grandom(100);

auto_twiddle(0);

hist_plot($data);
hist_plot($data, bt::Log);
hist_plot($data, bt::Linear(min => 0, drop_extremes => 0));
hist_plot(ones(20));
hist_plot(ones(20), bt::Log(normalize => 0));
plot(
	-fit => ds::Dist($data,
		binning => bt::NormFit,
		plotType => ppair::Lines
		lineWidth => 3,
		color => cl::LightRed
	),
	-data => ds::Dist($data,
		binning => bt::Linear(mark_empty_as => 'bad'),
		# Need a better default baseline for log-y scaling
		plotType => ppair::Histogram(baseline => 0.001),
	),
	y => {scaling => sc::Log, min => 0.1},
);

twiddle;