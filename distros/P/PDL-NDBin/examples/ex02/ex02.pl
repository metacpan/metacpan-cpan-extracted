use strict;
use warnings;
use PDL;
use PDL::NDBin;

my( $x, $y, $z ) = rcols 'table';
my $binner = PDL::NDBin->new( axes => [ [ 'x', min=>-0.5, max=>7.5, step=>1 ],
					[ 'y', min=>-0.5, max=>7.5, step=>1 ] ],
			      vars => [ [ 'x', 'Avg' ],
					[ 'y', 'Avg' ],
					[ 'z', 'Avg' ] ] );
$binner->process( x => $x, y => $y, z => $z );
my %results = $binner->output;
my @avg = map { $_->flat } @results{ qw/x y z/ };
wcols @avg, 'mean';
