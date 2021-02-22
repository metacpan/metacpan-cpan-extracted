use v5.24;
use warnings;
use Test::More;
use Quantum::Superpositions::Lazy qw(superpos with_sources);
use lib 't/lib';
use StateTesters;

##############################################################################
# A check of transformations - whether it morphs all the states.
##############################################################################

my $case = superpos(2, 3);
my $morphed = $case->transform(sub { shift() > 2 ? "yes" : "no" });

use Data::Dumper;
note Dumper(with_sources { $morphed->states });

ok $morphed eq "yes", "morph ok";
ok $morphed eq "no", "morph ok";

subtest "complex transformation test" => sub {
	my $another_case = superpos(6, 5, 4);
	my $morph_sub = sub {
		join '', @_;
	};

	# all states probability (1/2) * (1/3)
	my %wanted = (
		26 => '0.166',
		25 => '0.166',
		24 => '0.166',
		36 => '0.166',
		35 => '0.166',
		34 => '0.166',
	);

	my $result = $case->transform($morph_sub, $another_case);
	test_states(\%wanted, $result->states);
};

subtest "complex transformation test (three superpositions)" => sub {
	my $another_case = superpos(1);
	my $yet_another_case = superpos(4, 5);
	my $morph_sub = sub {
		join '', @_;
	};

	# all states probability (1/2) * 1 * (1/2)
	my %wanted = (
		214 => '0.250',
		215 => '0.250',
		314 => '0.250',
		315 => '0.250',
	);

	my $result = $case->transform($morph_sub, $another_case, $yet_another_case);
	test_states(\%wanted, $result->states);
};

done_testing;
