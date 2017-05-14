package Template::Flute::Increment;

use strict;
use warnings;

=head1 NAME

Template::Flute::Increment - Increment class for Template::Flute

=head1 SYNOPSIS

     $increment = new Template::Flute::Increment(start => 4, increment => 2);

=head1 CONSTRUCTOR

=head2 new

Create a Template::Flute::Increment object with the following parameters:

=over 4

=item start INT

Start value for the increment. Defaults to 1.

=item increment INT

Value added to the increment with each call of the increment method.
Defaults to 1.

=back

=cut

sub new {
	my ($class, $self);
	my (%params);
	
	$class = shift;
	%params = @_;

	# initial value
	if (exists $params{start}) {
		$self->{value} = $params{start};
	}
	else {
		$self->{value} = 1;
	}

	# increment
	if (exists $params{increment}) {
		$self->{increment} = $params{increment};
	}
	else {
		$self->{increment} = 1;
	}
	
	bless $self;

	return $self;
}

=head1 METHODS

=head2 value

Returns current value of the increment.

=cut

sub value {
	my $self = shift;

	return $self->{value};
}

=head2 increment

Applies increment to value of the increment.

=cut

sub increment {
	my $self = shift;

	$self->{value} += $self->{increment};
	return $self->{value};
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;

