package Number::Iterator;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.01';

use overload (
	'""' => sub {
		$_[0]->{value};
	},
	'++' => sub {
		$_[0]->iterate();
	},
	'--' => sub {
		$_[0]->deiterate();
	}
);

sub new {
	my ($self, %args) = @_;
	$args{value} = 0 unless $args{value};
	return bless \%args, $self;
}

sub iterate {
	my ($self) = @_;
	if (defined $self->{iterate}) {
		$self->{iterate}($self);
	} else {
		$self->{value} += $self->{interval};
	}
	return $self;
}

sub deiterate {
	my ($self) = @_;
	if (defined $self->{deiterate}) {
		$self->{deiterate}($self);
	} else {
		$self->{value} -= $self->{interval};
	}
	return $self;
}

sub value {
	my ($self, $val) = @_;
	$self->{value} = $val if (defined $val);
	return $self->{value};
}

sub interval {
	my ($self, $val) = @_;
	$self->{interval} = $val if (defined $val);
	return $self->{interval};
}

__END__;

1;

=head1 NAME

Number::Iterator - The great new Number::Iterator!

=head1 VERSION

Version 1.01

=cut

=head1 SYNOPSIS

	use Number::Iterator;

	my $iter = Number::Iterator->new(interval => 50);

	$iter++;

	$iter--;

	$iter->iterate;

	$iter->deiterate;

	$iter->value;

	$iter->interval;

...

	my $iter = Number::Iterator->new(
		interval => 50,
		iterate => sub {
			my ($self) = @_;
			($self->{value} ||= 1) *= $self->{interval};
		},
		deiterate => sub {
			my ($self) = @_;
                	$self->{value} /= $self->{interval};
		}
	);

=head1 AUTHOR

lnation, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-number-iterator at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Number-Iterator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Number::Iterator

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Number-Iterator>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Number-Iterator>

=item * Search CPAN

L<https://metacpan.org/release/Number-Iterator>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by lnation.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Number::Iterator
