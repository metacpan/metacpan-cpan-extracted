# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Optimization-NSGAII.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 5;

Test::More->builder->no_ending(1);

BEGIN { use_ok('Optimization::NSGAII','f_Optim_NSGAII') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
   
sub f_FON {
	
	my $x = shift;
	
	my $n = scalar(@$x);
	
	my $sum = 0;	
	for my $i(0..$n-1){ $sum += -($x->[$i] - 1/sqrt(3))**2 } ;	
	my $f1 = 1 - exp($sum);
	
	$sum = 0;	
	for my $i(0..$n-1){ $sum += -($x->[$i] + 1/sqrt(3))**2 } ;	
	my $f2 = 1 - exp($sum);

	my $out = [$f1,$f2];
	
	return $out;
};

my $pi = 3.14159265;

my $ref_input_output = f_Optim_NSGAII(
	{
		'nPop' 			=> 50,
		'nGen'  		=> 10,
		'bounds' 		=> [[-$pi,$pi],[-$pi,$pi],[-$pi,$pi]],
		'function' 		=> \&f_FON,
		'nProc'			=> 2,
		'filesDir'		=> '/tmp',	
		'verboseFinal'  => 0,	
		'distrib'       => [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.1],
		'scaleDistrib' => 0.05,
	},
);

ok( (scalar @{$ref_input_output->[0]}) == 50, 'correct length input population');
ok( (scalar @{$ref_input_output->[1]}) == 50, 'correct length output population');

ok( (scalar @{$ref_input_output->[0][0]}) == 3, 'correct length input individual');
ok( (scalar @{$ref_input_output->[1][0]}) == 2, 'correct length output individual');



