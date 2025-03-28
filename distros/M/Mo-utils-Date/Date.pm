package Mo::utils::Date;

use base qw(Exporter);
use strict;
use warnings;

use DateTime;
use English;
use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(check_date check_date_dmy check_date_ddmmyy check_date_order);

our $VERSION = 0.04;

sub check_date {
	my ($self, $key) = @_;

	if (! exists $self->{$key}) {
		return;
	}

	if (! defined $self->{$key}) {
		return;
	}

	# Check year format.
	if ($self->{$key} !~ m/^\-?(\d{1,4})\-?\d{0,2}\-?\d{0,2}$/ms) {
		err "Parameter '$key' is in bad format.",
			'Value' => $self->{$key},
		;
	}
	my $year = $1;

	# Check year greater than actual.
	if ($year > DateTime->now->year) {
		err "Parameter '$key' has year greater than actual year.";
	}

	return;
}

sub check_date_dmy {
	my ($self, $key) = @_;

	if (! exists $self->{$key}) {
		return;
	}

	if (! defined $self->{$key}) {
		return;
	}

	if ($self->{$key} !~ m/^(\d{1,2}).(\d{1,2}).(\d{4})$/ms) {
		err "Parameter '$key' is in bad format.",
			'Value' => $self->{$key},
		;
	}
	my ($day, $month, $year) = ($1, $2, $3);
	eval {
		DateTime->new(
			'day' => $1,
			'month' => $2,
			'year' => $3,
		);
	};
	if ($EVAL_ERROR) {
		err "Parameter '$key' is bad date.",
			'Value' => $self->{$key},
			'DateTime error' => $EVAL_ERROR,
		;
	}

	return;
}

sub check_date_ddmmyy {
	my ($self, $key) = @_;

	if (! exists $self->{$key}) {
		return;
	}

	if (! defined $self->{$key}) {
		return;
	}

	if ($self->{$key} !~ m/^(\d{2})(\d{2})(\d{2})$/ms) {
		err "Parameter '$key' is in bad date format.",
			'Value', $self->{$key},
		;
	}
	my ($day, $month, $year) = ($1, $2, $3);
	eval {
		DateTime->new(
			'day' => $1,
			'month' => $2,
			'year' => 2000 + $3,
		);
	};
	if ($EVAL_ERROR) {
		err "Parameter '$key' is bad date.",
			'Value' => $self->{$key},
			'DateTime error' => $EVAL_ERROR,
		;
	}

	return;
}

sub check_date_order {
	my ($self, $key1, $key2) = @_;

	if (! exists $self->{$key1} || ! exists $self->{$key2}) {
		return;
	}

	if (! defined $self->{$key1} || ! defined $self->{$key2}) {
		return;
	}

	my ($dt1, $dt2);
	if (ref $self->{$key1} eq 'DateTime') {
		$dt1 = $self->{$key1};
	} else {
		$dt1 = _construct_dt($self->{$key1});
	}
	if (ref $self->{$key2} eq 'DateTime') {
		$dt2 = $self->{$key2};
	} else {
		$dt2 = _construct_dt($self->{$key2});
	}

	my $cmp = DateTime->compare($dt1, $dt2);

	# dt1 >= dt2
	if ($cmp != -1) {
		err "Parameter '$key1' has date greater or same as parameter '$key2' date.";
	}

	return;
}

sub _construct_dt {
	my $date = shift;

	my ($year, $month, $day);
	if ($date =~ m/^(\-?\d{1,4})\-?(\d{0,2})\-?(\d{0,2})$/ms) {
		($year, $month, $day) = ($1, $2, $3);
	} else {
		err 'Cannot parse date/time string.',
			'Value' => $date,
		;
	}
	my $dt = eval {
		DateTime->new(
			'year' => $year,
			$month ? ('month' => $month) : (),
			$day ? ('day' => $day) : (),
		);
	};
	if ($EVAL_ERROR) {
		err "Cannot construct DateTime object from date.",
			'Value' => $date,
			'DateTime error' => $EVAL_ERROR,
		;
	}

	return $dt;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Mo::utils::Date - Mo date utilities.

=head1 SYNOPSIS

 use Mo::utils::Date qw(check_date);

 check_date($self, $key);
 check_date_dmy($self, $key);
 check_date_ddmmyy($self, $key);
 check_date_order($self, $key1, $key2);

=head1 DESCRIPTION

Utilities for checking of data values.

=head1 SUBROUTINES

=head2 C<check_date>

 check_date($self, $key);

I<Since version 0.01. Described functionality since version 0.02.>

Check parameter defined by C<$key> which is date and that date isn't greater
than actual year.

Possible dates:
 - YYYY-MM-DD
 - YYYY-M-D
 - YYYY-MM
 - YYYY-M
 - YYYY

Put error if check isn't ok.

Returns undef.

=head2 C<check_date_dmy>

 check_date_dmy($self, $key);

I<Since version 0.02. Described functionality since version 0.03.>

Check parameter defined by C<$key> which is date in right format.

Possible dates.
 - D.M.YYYY
 - DD.MM.YYYY

Date is checked via L<DateTime> if is real.

Put error if check isn't ok.

Returns undef.

=head2 C<check_date_ddmmyy>

 check_date_ddmmyy($self, $key);

I<Since version 0.03.>

Check parameter defined by C<$key> which is date in ddmmyy format.

Possible dates.
 - DDMMYY

Function is working only for date years > 2000.

Date is checked via L<DateTime> if it is real.

Put error if check isn't ok.

Returns undef.

=head2 C<check_date_order>

 check_date_order($self, $key1, $key2);

I<Since version 0.01. Described functionality since version 0.04.>

Check if date with C<$key1> is lesser than date with C<$key2>.

Possible date formats:

=over

=item * YYYY-MM-DD

=item * -YYYY-MM-DD

=item * YEAR

=item * L<DateTime> object

=back

Put error if check isn't ok.

Returns undef.

=head1 ERRORS

 check_date():
         Parameter '%s' for date is in bad format.
                 Value: %s
         Parameter '%s' has year greater than actual year.

 check_date_dmy():
         Parameter '%s' for date is in bad format.
                 Value: %s
         Parameter '%s' is bad date.
                 Value: %s
                 DateTime error: %s

 check_date_ddmmyy():
         Parameter '%s' for date is in bad date format.
                 Value: %s
         Parameter '%s' is bad date.
                 Value: %s
                 DateTime error: %s

 check_date_order():
         Cannot parse date/time string.
                 Value: %s
         Cannot construct DateTime object from date.
                 Value: %s
                 DateTime error: %s
         Parameter '%s' has date greater or same as parameter '%s' date.

=head1 EXAMPLE1

=for comment filename=check_date_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Date qw(check_date);

 my $self = {
         'key' => '2022-01-15',
 };
 check_date($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE2

=for comment filename=check_date_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Date qw(check_date);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'foo',
 };
 check_date($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..Utils.pm:?] Parameter 'key' is in bad format.

=head1 EXAMPLE3

=for comment filename=check_date_ddmmyy_ok.pl

 use strict;
 use warnings;

 use Mo::utils::Date qw(check_date_ddmmyy);

 my $self = {
         'key' => '151120',
 };
 check_date_ddmmyy($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE4

=for comment filename=check_date_ddmmyy_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::Date qw(check_date_ddmmyy);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'foo',
 };
 check_date_ddmmyy($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [..Utils.pm:?] Parameter 'key' for date is in bad format.

=head1 DEPENDENCIES

L<DateTime>,
L<English>,
L<Exporter>,
L<Error::Pure>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Mo::utils>

Mo utilities.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Mo-utils-Date>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2022-2024

BSD 2-Clause License

=head1 VERSION

0.04

=cut
