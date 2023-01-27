package Random::Day::InTheFuture;

use base qw(Random::Day);
use strict;
use warnings;

use DateTime;

our $VERSION = 0.13;

sub new {
	my ($class, @params) = @_;

	# Set minimal date.
	my $dt_from_exists = 0;
	foreach (my $i = 0; $i < @params; $i++) {
		if ($i % 1 == 1 && $params[$i] eq 'dt_from') {
			$params[$i+1] = DateTime->now;
			$dt_from_exists = 1;
		}
	}
	if (! $dt_from_exists) {
		push @params, 'dt_from', DateTime->now;
	}

	# Object.
	return bless $class->SUPER::new(@params), $class;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Random::Day::InTheFuture - Class for random day generation in the future.

=head1 SYNOPSIS

 use Random::Day::InTheFuture;

 my $obj = Random::Day::InTheFuture->new(%params);
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

 my $obj = Random::Day::InTheFuture->new(%params);

Constructor.

=over 8

=item * C<day>

Day.

Default value is undef.

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
         From Random::Day::random_day():
                 Day cannot be a zero.
                 Day isn't number.

 random_day_month():
         From Random::Day::random_day_month():
                 Cannot create DateTime object.
                 Day cannot be a zero.
                 Day isn't number.

 random_day_month_year():
         From Random::Day::random_day_year():
                 Cannot create DateTime object.
                         Error: %s
                 Day cannot be a zero.
                 Day isn't number.

 random_month():
         From Random::Day::random_momth():
                 Cannot create DateTime object.
                         Error: %s

 random_month_year():
         From Random::Day::random_month_year():
                 Begin of expected month is lesser than minimal date.
                         Expected year: %s
                         Expected month: %s
                         Minimal year: %s
                         Minimal month: %s
                 Cannot create DateTime object.
                         Error: %s
                 End of expected month is greater than maximal date.
                         Expected year: %s
                         Expected month: %s
                         Maximal year: %s
                         Maximal month: %s

 random_year():
         From Random::Day::random_year():
                 Year is greater than maximal year.
                         Expected year: %s
                         Maximal year: %s
                 Year is lesser than minimal year.
                         Expected year: %s
                         Minimal year: %s

=head1 EXAMPLE

=for comment filename=get_random_day_in_the_future.pl

 use strict;
 use warnings;

 use Random::Day::InTheFuture;

 # Object.
 my $obj = Random::Day::InTheFuture->new;

 # Get date.
 my $dt = $obj->get;

 # Print out.
 print $dt->ymd."\n";

 # Output like:
 # \d\d\d\d-\d\d-\d\d

=head1 DEPENDENCIES

L<Random::Day>,
L<DateTime>.

=head1 SEE ALSO

=over

=item L<Data::Random>

Perl module to generate random data

=item L<Random::Day>

Class for random day generation.

=item L<Random::Day::InThePast>

Class for random day generation in the past.

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

0.13

=cut
