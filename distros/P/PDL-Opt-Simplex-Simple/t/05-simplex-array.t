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




my $count = 0;
my $simpl = PDL::Opt::Simplex::Simple->new(
        vars => {
                x => {
			values => [ 30, -30 ],
			enabled => 1,
			round_each => 0.0005,
			round_result => 0.5,
			#minmax => [[-35 => 50]]
		},
        },
	opts => { ssize => 3 },
	max_iter => 100,
	tolerance => 1e-6,
        f => sub {
			my $v = shift;
			$count++;
			
			# Parabola with minima at x = -3
			return (($v->{x}[0]+3)**2 - 5) + (($v->{x}[1]+7)**2 - 9);
		},
	log => sub {
			my $vars = shift;
			my $state = shift;

			print "$count [$state->{ssize}]: x0=$vars->{x}[0] x1=$vars->{x}[1]\n";

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
ok(abs($simpl->get_result_simple()->{x}[0] - (-3)) < 1e-6);
ok(abs($simpl->get_result_simple()->{x}[1] - (-7)) < 1e-6);

