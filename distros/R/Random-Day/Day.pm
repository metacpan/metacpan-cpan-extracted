package Random::Day;

use strict;
use warnings;

use Class::Utils qw(set_params);
use DateTime;
use DateTime::Event::Random;
use DateTime::Event::Recurrence;
use English;
use Error::Pure qw(err);

our $VERSION = 0.12;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Day.
	$self->{'day'} = undef;

	# DateTime object from.
	$self->{'dt_from'} = DateTime->new(
		'year' => 1900,
	);

	# DateTime object to.
	$self->{'dt_to'} = DateTime->new(
		'year' => 2050,
	);

	# Month.
	$self->{'month'} = undef;

	# Year.
	$self->{'year'} = undef;

	# Process parameters.
	set_params($self, @params);

	return $self;
}

# Get DateTime object with random date.
sub get {
	my ($self, $date) = @_;

	if ($self->{'year'}) {
		if ($self->{'month'}) {
			if ($self->{'day'}) {
				$date = $self->random_day_month_year(
					$self->{'day'},
					$self->{'month'},
					$self->{'year'},
				);
			} else {
				$date = $self->random_month_year(
					$self->{'month'},
					$self->{'year'},
				);
			}
		} else {
			if ($self->{'day'}) {
				$date = $self->random_day_year(
					$self->{'day'},
					$self->{'year'},
				);
			} else {
				$date = $self->random_year($self->{'year'});
			}
		}
	} else {
		if ($self->{'month'}) {
			if ($self->{'day'}) {
				$date = $self->random_day_month(
					$self->{'day'},
					$self->{'month'},
				);
			} else {
				$date = $self->random_month($self->{'month'});
			}
		} else {
			if ($self->{'day'}) {
				$date = $self->random_day($self->{'day'});
			} else {
				$date = $self->random;
			}
		}
	}

	return $date;
}

# Random DateTime object for day.
sub random {
	my $self = shift;

	my $daily = DateTime::Event::Recurrence->daily;

	return $daily->next($self->_range);
}

# Random DateTime object for day defined by day.
sub random_day {
	my ($self, $day) = @_;

	$self->_check_day($day);
	my $monthly_day = DateTime::Event::Recurrence->monthly(
		'days' => $day,
	);

	return $monthly_day->next($self->random);
}

# Random DateTime object for day defined by day and month.
sub random_day_month {
	my ($self, $day, $month) = @_;

	$self->_check_day($day);
	my $yearly_day_month = DateTime::Event::Recurrence->yearly(
		'days' => $day,
		'months' => $month,
	);
	my $dt = $yearly_day_month->next($self->random);
	if (! defined $dt) {
		err 'Cannot create DateTime object.';
	}

	return $dt;
}

# DateTime object for day defined by day, month and year.
sub random_day_month_year {
	my ($self, $day, $month, $year) = @_;

	$self->_check_day($day);
	my $dt = eval {
		DateTime->new(
			'day' => $day,
			'month' => $month,
			'year' => $year,
		);
	};
	if ($EVAL_ERROR) {
		err 'Cannot create DateTime object.',
			'Error', $EVAL_ERROR;
	}

	return $dt;
}

# Random DateTime object for day defined by month.
sub random_month {
	my ($self, $month) = @_;

	my $random_day = $self->_range;

	return $self->random_month_year($month, $random_day->year);
}

# Random DateTime object for day defined by month and year.
sub random_month_year {
	my ($self, $month, $year) = @_;

	my $after = eval {
		DateTime->new(
			'day' => 1,
			'month' => $month,
			'year' => $year,
		);
	};
	if ($EVAL_ERROR) {
		err 'Cannot create DateTime object.',
			'Error', $EVAL_ERROR;
	}

	my $before = $after->clone;
	$before->add(months => 1)->subtract(days => 1);

	my $daily = DateTime::Event::Recurrence->daily;
	return $daily->next(DateTime::Event::Random->datetime(
		'after' => $after,
		'before' => $before,
	));
}

# Random DateTime object for day defined by year.
sub random_year {
	my ($self, $year) = @_;

	my $daily = DateTime::Event::Recurrence->daily;

	return $daily->next(DateTime::Event::Random->datetime(
		'after' => DateTime->new(
			'day' => 1,
			'month' => 1,
			'year' => $year,
		),
		'before' => DateTime->new(
			'day' => 31,
			'month' => 12,
			'year' => $year,
		),
	));
}

# Check day.
sub _check_day {
	my ($self, $day) = @_;

	if ($day !~ m/^\d+$/ms) {
		err "Day isn't positive number.";
	}
	if ($day == 0) {
		err 'Day cannot be a zero.';
	}
	return;
}

# Random date in range.
sub _range {
	my $self = shift;

	return DateTime::Event::Random->datetime(
		'after' => $self->{'dt_from'},
		'before' => $self->{'dt_to'},
	);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Random::Day - Class for random day generation.

=head1 SYNOPSIS

 use Random::Day;

 my $obj = Random::Day->new(%params);
 my $dt = $obj->get;
 my $dt = $obj->random;
 my $dt = $obj->random_day($day);
 my $dt = $obj->random_day_month($day, $month);
 my $dt = $obj->random_day_month_year($day, $month, $year);
 my $dt = $obj->random_month($month);
 my $dt = $obj->random_month_year($month, $year);
 my $dt = $obj->random_year($year);

=head1 METHODS

=head2 C<new>

 my $obj = Random::Day->new(%params);

Constructor.

=over 8

=item * C<day>

Day.

Default value is undef.

=item * C<dt_from>

DateTime object from.

Default value is DateTime object for 1900 year.

=item * C<dt_to>

DateTime object to.

Default value is DateTime object for 2050 year.

=item * C<month>

Month.

Default value is undef.

=item * C<year>

Year.

Default value is undef.

=back

=head2 C<get>

 my $dt = $obj->get;

Get random date defined by constructor parameters.

Returns DateTime object for date.

=head2 C<random>

 my $dt = $obj->random;

Get random date.

Returns DateTime object for date.

=head2 C<random_day>

 my $dt = $obj->random_day($day);

Get random date defined by day.

Returns DateTime object for date.

=head2 C<random_day_month>

 my $dt = $obj->random_day_month($day, $month);

Get random date defined by day and month.

Returns DateTime object for date.

=head2 C<random_day_month_year>

 my $dt = $obj->random_day_month_year($day, $month, $year);

Get date defined by day, month and year.

Returns DateTime object for date.

=head2 C<random_month>

 my $dt = $obj->random_month($month);

Get random date defined by month.

Returns DateTime object for date.

=head2 C<random_month_year>

 my $dt = $obj->random_month_year($month, $year);

Get random date defined by month and year.

Returns DateTime object for date.

=head2 C<random_year>

 my $dt = $obj->random_year($year);

Get random date defined by year.

Returns DateTime object for date.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 random_day():
         Day cannot be a zero.
         Day isn't number.

 random_day_month():
         Cannot create DateTime object.
         Day cannot be a zero.
         Day isn't number.

 random_day_month_year():
         Cannot create DateTime object.
                 Error: %s
         Day cannot be a zero.
         Day isn't number.

 random_month():
         Cannot create DateTime object.
                 Error: %s

 random_month_year():
         Cannot create DateTime object.
                 Error: %s

=head1 EXAMPLE

=for comment filename=get_random_day.pl

 use strict;
 use warnings;

 use Random::Day;

 # Object.
 my $obj = Random::Day->new;

 # Get date.
 my $dt = $obj->get;

 # Print out.
 print $dt->ymd."\n";

 # Output like:
 # \d\d\d\d-\d\d-\d\d

=head1 DEPENDENCIES

L<Class::Utils>,
L<DateTime>,
L<DateTime::Event::Random>,
L<DateTime::Event::Recurrence>,
L<English>,
L<Error::Pure>.

=head1 SEE ALSO

=over

=item L<Data::Random>

Perl module to generate random data

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Random-Day>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2013-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.12

=cut
