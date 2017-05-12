use strict;
use Statistics::PointEstimation;
use POSIX;

my $PI=3.14159265358979323846;
my ($rand,$rand1,$rand2);
my ($i,$j,$success,$fail);

$success=0;
for($j=1;$j<=500;$j++)
{
	my @r=();
	for($i=1;$i<=32;$i++)
	{

		$rand=rand(1)-0.5;
		push @r,$rand;
	}

	my $stat = new Statistics::PointEstimation;
	$stat->set_significance(95);
	$stat->add_data(@r);

	 $success++ if(($stat->upper_clm()>=0)&&($stat->lower_clm()<=0));
	$stat->output_confidence_interval() if $j==500;
	$stat->print_confidence_interval() if $j==500;
}
$j--;
print "$j trials $success successes ",$j-$success, "failure ", ($success)/$j*100, "% success rate\n";





