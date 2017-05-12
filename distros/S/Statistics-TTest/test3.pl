use Statistics::PointEstimation;
use Statistics::TTest;
my @r1=();
my @r2=();
my $rand;
	
  for($i=1;$i<=32;$i++) #generate a uniformly distributed sample with mean=5   
  {

          $rand=rand(10);
          push @r1,$rand;
          $rand=rand(10)-2;
          push @r2,$rand;
  }


my $ttest = new Statistics::TTest;  
$ttest->set_significance(90);
$ttest->load_data(\@r1,\@r2);  
$ttest->output_t_test();
$ttest->set_significance(99);
$ttest->print_t_test();



