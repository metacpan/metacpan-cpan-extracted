package Readonly::Values::Months;

use strict;
use warnings;

use Readonly::Enum;
use Readonly;
use Exporter qw(import);

=head1 NAME

Readonly::Values::Months - Months Constants

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Readonly::Values::Months;

    # Simple month constants
    print "January is month number $JAN\n";    # January is month number 1
    print "December is month number $DEC\n";   # December is month number 12

    # Lookup a month number by name (case-insensitive keys)
    my $num = $months{'april'};     # 4
    print "April => $num\n";

    # Iterate full month names
    for my $name (@month_names) {
        printf "%-9s => %2d\n", ucfirst($name), $months{$name};
    }

    # Short names (first three letters)
    print 'Abbreviations: ', join(', ', @short_month_names), "\n";
    # Abbreviations: jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec

    # Exported symbols:
    #   $JAN ... $DEC
    #   %months
    #   @month_names
    #   @short_month_names

=cut

Readonly::Enum our ($JAN, $FEB, $MAR, $APR, $MAY, $JUN, $JUL, $AUG, $SEP, $OCT, $NOV, $DEC) => 1;
Readonly::Hash our %months => (
	'jan' => $JAN,
	'january' => $JAN,
	'feb' => $FEB,
	'february' => $FEB,
	'mar' => $MAR,
	'march' => $MAR,
	'apr' => $APR,
	'april' => $APR,
	'may' => $MAY,
	'jun' => $JUN,
	'june' => $JUN,
	'jul' => $JUL,
	'july' => $JUL,
	'aug' => $AUG,
	'august' => $AUG,
	'sep' => $SEP,
	'september' => $SEP,
	'oct' => $OCT,
	'october' => $OCT,
	'nov' => $NOV,
	'november' => $NOV,
	'dec' => $DEC,
	'december' => $DEC
);

Readonly::Array our @month_names => (
	'january',
	'february',
	'march',
	'april',
	'may',
	'june',
	'july',
	'august',
	'september',
	'october',
	'november',
	'december'
);

Readonly::Array our @short_month_names => map { _shorten($_) } @month_names;

our @EXPORT = qw(
	$JAN $FEB $MAR $APR $MAY $JUN $JUL $AUG $SEP $OCT $NOV $DEC
	%months
	@month_names
	@short_month_names
);

# Helper routine: Shorten strings to their first three characters
sub _shorten {
	return substr(shift, 0, 3);
};

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

=head1 SEE ALSO

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-readonly-values-months at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Readonly-Values-Months>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Readonly::Values::Months

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Readonly-Values-Months>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Readonly-Values-Months>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Readonly-Values-Months>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Readonly::Values::Months>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
