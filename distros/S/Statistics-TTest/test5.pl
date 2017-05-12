#!/usr/local/bin/perl -w
use lib qw (/homes/yunfang/work/yahoo/jupiter/Metric);
use Statistics::PointEstimation;
use Statistics::TTest;
	
my %sample1=(
	'count' =>30,
	'mean' =>3.98,
	'variance' =>2.63
		);

my %sample2=(
	'count'=>30,
	'mean'=>3.67,
	'variance'=>1.12
	);


my $ttest = new Statistics::TTest::Sufficient;  
$ttest->set_significance(90);
$ttest->load_data(\%sample1,\%sample2);  
$ttest->output_t_test();
#$ttest->s1->print_confidence_interval();
$ttest->set_significance(99);
$ttest->output_t_test();
#$ttest->s1->print_confidence_interval();


