use strict;
use warnings;
use PDL;
use Prima qw(Application);
use PDL::Graphics::Prima;


my $t_data = sequence(6) / 0.5 + 1;
print "t_data are $t_data\n";
my $y_data = exp($t_data);

my $wDisplay = Prima::MainWindow->create(
	text    => 'Graph Test',
	size	=> [300, 300],
);

$wDisplay->insert('Plot',
	-function => ds::Func(\&PDL::exp, color => cl::Blue),
	-data => ds::Pair($t_data, $y_data, color => cl::Red),
	pack => { fill => 'both', expand => 1},
#	y => {scaling => sc::Log},
);

run Prima;
