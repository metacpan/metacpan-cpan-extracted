package Random::Set;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);

our $VERSION = 0.05;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Precision.
	$self->{'precision'} = 100;

	# Set.
	$self->{'set'} = [];

	# Process parameters.
	set_params($self, @params);

	# Check set.
	my $full = 0;
	foreach my $set_ar (@{$self->{'set'}}) {
		$full += $set_ar->[0];
	}
	if ($full != 1) {
		err 'Bad set sum. Must be 1.';
	}

	# Create set.
	$self->{'_set'} = [];
	foreach my $set_ar (@{$self->{'set'}}) {
		push @{$self->{'_set'}}, ($set_ar->[1])
			x ($self->{'precision'} * $set_ar->[0]);
	}

	return $self;
}

# Get random result.
sub get {
	my $self = shift;
	my $index = int(rand(@{$self->{'_set'}}));
	return $self->{'_set'}->[$index];
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Random::Set - Class for random set generation.

=head1 SYNOPSIS

 use Random::Set;
 my $obj = Random::Set->new(%params);
 my $random = $obj->get;

=head1 METHODS

=over 8

=item C<new(%params)>

 Constructor.

=over 8

=item * C<precision>

 Precision.
 Default value is 100.

=item * C<set>

 Set definition.
 Set is array of arrays with pairs of probability and value.
 Default value is [].
 It is required.
 Sumary of probabilities must be 1.

=back

=item C<get()>

 Get random value from set.
 Returns value from set.

=back

=head1 ERRORS

 new():
         Bad set sum. Must be 1.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Random::Set;

 # Object.
 my $obj = Random::Set->new(
         'set' => [
                 [0.5, 'foo'],
                 [0.5, 'bar'],
         ],
 );

 # Get random data.
 my $random = $obj->get;

 # Print out.
 print $random."\n";

 # Output like:
 # foo|bar

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>.

=head1 SEE ALSO

=over

=item L<Random::Day>

Class for random day generation.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Random-Set>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © Michal Josef Špaček 2013-2017
 BSD 2-Clause License

=head1 VERSION

0.05

=cut
