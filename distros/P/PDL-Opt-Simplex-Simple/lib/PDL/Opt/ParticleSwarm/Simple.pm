#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Library General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#  Copyright (C) 2023- eWheeler, Inc. L<https://www.linuxglobal.com/>
#  Originally written by Eric Wheeler, KJ7LNW
#  All rights reserved.
#
#  All tradmarks, product names, logos, and brands are property of their
#  respective owners and no grant or license is provided thereof.

package PDL::Opt::ParticleSwarm::Simple;

use 5.010;
use strict;
use warnings;

use PDL;
use PDL::Opt::ParticleSwarm;
use PDL::Opt::Simplex::Simple;

use parent 'PDL::Opt::Simplex::Simple';

sub new
{
	my ($class, %args) = @_;

	if (defined($args{max_iter}) && defined($args{opts}{-iterations}) && $args{max_iter} != $args{opts}{-iterations})
	{
		die "You defined both {max_iter} and {opts}{-iterations}, but they differ: $args{max_iter} != $args{opts}{-iterations}";
	}

	# One will get the other:
	$args{max_iter} //= $args{opts}{-iterations};
	$args{opts}{-iterations} //= $args{max_iter};

	return PDL::Opt::Simplex::Simple::new($class, %args);
}

sub __optimize
{
	my ($self, $vec_initial) = @_;

	my $var_min = $self->_build_simplex_var_min();
	my $var_max = $self->_build_simplex_var_max();

	my $pso = PDL::Opt::ParticleSwarm->new(
		%{ $self->{opts} },
		-posMin => $var_min,
		-posMax => $var_max,
		-initialGuess => $vec_initial,

		-fitFunc =>
			sub {
				my ($vec) = @_;

				return $self->_simplex_f($vec);
			},
		-logFunc =>
			sub {
				return $self->_simplex_log(@_, pdl(inf));
			}
			);

	$pso->optimize();

	my $vec_optimal = $pso->getBestPos();
	my $optval = $pso->getBestFit();

	my $opt_ssize = inf; # unused in particle swarm

	return ($vec_optimal, $opt_ssize, $optval);
}

1;

__END__


=head1 NAME

PDL::Opt::ParticleSwarm::Simple - An easy to use particle swarm optimizer

=head1 SYNOPSIS

	use PDL::Opt::ParticleSwarm::Simple;

	# Simple single-variable invocation

	$simpl = PDL::Opt::ParticleSwarm::Simple->new(
		vars => {
			# initial guess for x
			x => 1 
		},
		f => sub { 
				my $vars = shift;

				# Parabola with minima at x = -3
				return (($vars->{x}+3)**2 - 5) 
			},
		opts => {
			# Options from PDL::Opt::ParticleSwarm
		}
	);

	$simpl->optimize();
	$result_vars = $simpl->get_result_simple();

	print "x=" . $result_vars->{x} . "\n";  # x=-3

	$result_vars = $simpl->optimize();

	use Data::Dumper;
	print Dumper($result_vars);


=head1 DESCRIPTION

This class uses L<PDL::Opt::ParticleSwarm> to find the values for C<vars>
that cause the C<f> coderef to return the minimum value.  The difference
between L<PDL::Opt::ParticleSwarm> and L<PDL::Opt::ParticleSwarm::Simple> is that
L<PDL::Opt::ParticleSwarm> expects all data to be in PDL format and it is
more complicated to manage, whereas, L<PDL::Opt::ParticleSwarm:Simple> uses
all scalar Perl values. (PDL values are supported, too)

=head1 FUNCTIONS

=over 4

=item * $self->new(opts => \%args) - Instantiate class

This is a subclass implementation of Particle Swarm based on
L<PDL::Opt::Simplex::Simple>.  Many other features are available, so please see
the L<PDL::Opt::Simplex::Simple> documentation for full details.

=back

=head1 OPTIONS

See L<PDL::Opt::ParticleSwarm> for options available above in C<opts>.

=head1 SEE ALSO

=over 4

=item L<PDL::Opt::ParticleSwarm> - A PDL implementation of Particle Swarm

=item L<PDL::Opt::Simplex::Simple> - Use names for Simplex-optimized values

=item L<PDL::Opt::Simplex> - A PDL implementation of the Simplex optimization algorithm

=back

=head1 AUTHOR

Originally written by Eric Wheeler, KJ7LNW for Zeke to optimize PID controller
values for an antenna rotors controller to contact the International Space
Station.  More project information is available here:
L<https://youtu.be/vrlw4QPKMRY>

=head1 COPYRIGHT

Copyright (C) 2023 Eric Wheeler, KJ7LNW

This module is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your
option) any later version.

This module is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with this module. If not, see <http://www.gnu.org/licenses/>.
