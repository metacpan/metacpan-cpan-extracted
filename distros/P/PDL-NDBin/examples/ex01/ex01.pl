use strict;
use warnings;
use PDL;
use PDL::NDBin;

my( $prestige, $income, $education ) = rcols 'table';
#wcols $prestige, $income, $education;

print "Histogram:\n";
{
	my $binner = PDL::NDBin->new( axes => [ [ 'Income', min=>0, max=>100, step=>10 ] ],
				      vars => [ [ 'Income', 'Count' ] ] );
	$binner->process( Income => $income );
	my %results = $binner->output;
	print "  ", $results{Income}, "\n\n";
}

print "Histogram with PDL:\n";
print "  ", ( hist( $income, 0,100,10 ) )[1], "\n\n";

print "Stem-and-leaf plot:\n";
{
	my $plot = sub {
		my $iter = shift;
		#printf "  %d: %s\n", $iter->bin, $iter->want->nelem ? $iter->selection : '[]';
		my @list = $iter->selection->list;
		printf "  %d| %s\n", $iter->bin, join '', map { $_ % 10 } sort @list;
	};
	my $binner = PDL::NDBin->new( axes => [ [ 'Income', min=>0, max=>100, step=>10 ] ],
				      vars => [ [ 'Income', $plot ] ] );
	$binner->process( Income => $income );
}
print "\n";
