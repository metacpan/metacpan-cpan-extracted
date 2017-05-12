use strict;
use warnings;
use PDL;
use PDL::NDBin;

my $binner = PDL::NDBin->new( axes => [ [ longitude => min => -60, max => 60, step => 40 ],
					[ latitude  => min => -60, max => 60, step => 40 ] ],
			      vars => [ [ avg    => 'Avg'    ],
					[ stddev => 'StdDev' ],
					[ count  => 'Count'  ] ] );

for my $file ( glob '??.txt' ) {
	my( $longitude, $latitude, $albedo, $flux, $windspeed ) = rcols $file;
	$binner->process( longitude => $longitude,
			  latitude  => $latitude,
			  avg       => $flux,
			  stddev    => $flux,
			  count     => $flux );
}

my %results = $binner->output;
print "Average flux:\n", $results{avg}, "\n";
print "Standard deviation of flux:\n", $results{stddev}, "\n";
print "Number of observations per bin:\n", $results{count}, "\n";
