use 5.006;
use strict;
use warnings;
use Test::More;

use PDL;
use PDL::Opt::Simplex::Simple;
#use Data::Dumper;

plan tests => 2;

$SIG{__DIE__} = \&backtrace;

sub _build_stack
{
	my $i = 0;
	my $stackoff = 1;

	my @msg;
	while (my @c = caller($i++)) {
		my @c0     = caller($i);
		my $caller = '';

		$caller = " ($c0[3])" if (@c0);
		push @msg, "  " . ($i - $stackoff) . ". $c[1]:$c[2]:$caller while calling $c[3]" if $i > $stackoff;
	}

	return reverse @msg;
}

sub backtrace
{
	my $self = shift;
	my $fh = shift || \*STDERR;

	foreach my $l (reverse _build_stack()) {
		print $fh "$l\n";
	}
}


# This tests two things:
#   1. multi-variable PDL-based optimization
#   2. values starting at the same value defined by `minmax` complete successfully.
#      There have been some issues starting out at max values, so we start x on
#      max and y on min to test and see if it succeeds.  See the comment at the
#      top of PDL::Opt::Simplex::Simple->_simplex_f() where it clamps to min/max
#      and injects it into simplex's internal piddle.


my $count = 0;
my $simpl = PDL::Opt::Simplex::Simple->new(
        vars => {
                x => {
			values => pdl(50), # starts at max
			enabled => 1,
			round_each => 0.0005,
			round_result => 0.5,
			minmax => [[-35 => 50]]
		},
                y => {
			values => pdl(-35), # starts at min
			enabled => 1,
			round_each => 0.0005,
			round_result => 0.5,
			minmax => [[-35 => 50]]
		},
        },
	opts => {
		ssize => 3,
		tolerance => 1e-6,
	},
	max_iter => 100,
        f => sub {
			my $v = shift;
			$count++;
			
			# Parabola with minima at x=-3,y=-7 == -14
			return (($v->{x}+3)**2 - 5) + (($v->{y}+7)**2 - 9);
		},
	log => sub {
			my $vars = shift;
			my $state = shift;

			$vars->{y} //= '';
			print "$count [$state->{ssize}]: x=$vars->{x} y=$vars->{y}\n";

			#print "Log: " . Dumper 
			#	{
			#		vars => PDL::Opt::Simplex::Simple::dumpify($vars),
			#		state => PDL::Opt::Simplex::Simple::dumpify($state),
			#	};
		}
);

$simpl->optimize;

#print "optimize: " . Dumper(PDL::Opt::Simplex::Simple::dumpify($simpl->optimize));
#print "best vec: " . $simpl->{best_vec}. "\n";
#print " optimal: " . $simpl->{vec_optimal}. "\n";
#print "expanded: " . Dumper(PDL::Opt::Simplex::Simple::dumpify($simpl->get_result_expanded()));
#print "  simple: " . Dumper(PDL::Opt::Simplex::Simple::dumpify($simpl->get_result_simple()));
ok(abs($simpl->get_result_simple()->{x} - (-3)) < 1e-6);
ok(abs($simpl->get_result_simple()->{y} - (-7)) < 1e-6);

