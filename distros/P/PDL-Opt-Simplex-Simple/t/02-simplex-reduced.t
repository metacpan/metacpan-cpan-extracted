use 5.006;
use strict;
use warnings;
use Test::More;

use PDL::Opt::Simplex::Simple;

plan tests => 1;

my $count = 0;
my $simpl = PDL::Opt::Simplex::Simple->new(
	reduce_search => 1, # <<<
        vars => {
                x => 30
	},
	ssize => 3,
	max_iter => 100,
	tolerance => 1e-6,
        f => sub {
			my $v = shift;
			$count++;

                        # Parabola with minima at x = -3
                        return (($v->{x}+3)**2 - 5);
                },
	log => sub {

			my ($vars, $state) = @_;

			print "$count [$state->{ssize}]: x=$vars->{x}\n";
		}
);

$simpl->optimize;

#print "  simple: " . Dumper(PDL::Opt::Simplex::Simple::dumpify($simpl->get_result_simple()));

ok(abs($simpl->get_result_simple()->{x} - (-3)) < 1e-6);

