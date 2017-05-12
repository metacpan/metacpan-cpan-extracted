use strict;
use warnings;
use PDL;
use PDL::NDBin;
use List::Util 'reduce';
use Term::ProgressBar::Simple;

my $progress;
my $binner = PDL::NDBin->new( axes => [ [ longitude => min => -60, max => 60, step => 40 ],
					[ latitude  => min => -60, max => 60, step => 40 ] ],
			      vars => [ [ avg    => 'Avg' ],
					[ dummy  => sub { sleep 1; $progress++; return } ] ] );
my( $longitude, $latitude, $albedo, $flux, $windspeed ) = rcols '01.txt';
$binner->autoscale( longitude => $longitude,
		    latitude  => $latitude,
		    avg       => $flux,
		    dummy     => null );
my $N = reduce { our $a * our $b } map { $_->{n} } $binner->axes;
$progress = Term::ProgressBar::Simple->new( $N );
$binner->process;
print "Average flux:\n", $binner->output->{avg}, "\n";
