#!perl

# use Test::More tests => 2;
use Test::More skip_all => 'This test needs fixed.';
use Test::Output;
use t::lib::MachineTest;
use File::Spec::Functions qw( catdir curdir rel2abs );

my $dir = catdir( rel2abs(curdir()), qw( t MachineTest ) );
my $expected;



foreach my $i (1 .. 10) {
	$expected_1 .= <<"EOF"
Object number $i ran.





------------------------------------------------------------





EOF

}

foreach my $j (1 .. 10) {
	if ($j % 5 == 0) {
		$expected_2 .= <<"EOF"


Skipping build number $j.




------------------------------------------------------------





EOF
	} else {
		$expected_2 .= <<"EOF"
Object number $j ran.





------------------------------------------------------------





EOF
	}
}

diag("Test directory: $dir");

sub test_machine_1 {
	t::lib::MachineTest->default_machine( common => [ image_dir, $dir ] )->run();
}

sub test_machine_2 {
	t::lib::MachineTest->default_machine( common => [ image_dir, $dir ], skip => [5, 10] )->run();
}

stdout_is ( \&test_machine_1, $expected_1, '::Util::Machine gives expected output.');
stdout_is ( \&test_machine_2, $expected_2, 'skip works.');
