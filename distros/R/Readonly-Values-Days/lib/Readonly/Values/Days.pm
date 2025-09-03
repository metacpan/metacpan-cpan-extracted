package Readonly::Values::Days;

use strict;
use warnings;

use Readonly::Enum;
use Readonly;
use Exporter qw(import);

=head1 NAME

Readonly::Values::Days - Days Constants

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Readonly::Values::Days;

    # Iterate full day names
    for my $name (@day_names) {
        printf "%-9s => %2d\n", ucfirst($name), $days{$name};
    }

=cut

Readonly::Enum our ($MON, $TUE, $WED, $THU, $FRI, $SAT, $SUN) => 1;

Readonly::Hash our %days => (
	# Full names
	'monday' => $MON,
	'tuesday' => $TUE,
	'wednesday' => $WED,
	'thursday' => $THU,
	'friday' => $FRI,
	'saturday' => $SAT,
	'sunday' => $SUN,

	# Abbreviations
	'mon' => $MON,
	'tue' => $TUE,
	'wed' => $WED,
	'thu' => $THU,
	'fri' => $FRI,
	'sat' => $SAT,
	'sun' => $SUN
);

Readonly::Array our @day_names => (
	'monday',
	'tuesday',
	'wednesday',
	'thursday',
	'friday',
	'saturday',
	'sunday'
);

Readonly::Array our @short_day_names => map { _shorten($_) } @day_names;

Readonly::Hash our %day_names_to_short => map { $_ => _shorten($_) } @day_names;

our @EXPORT = qw(
	$MON $TUE $WED $THU $FRI $SAT $SUN
	%days
	@day_names
	@short_day_names
	%day_names_to_short
);

# Helper routine: Shorten strings to their first three characters
sub _shorten {
	my $str = $_[0];

	return unless defined $str;
	return substr($str, 0, 3);
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

=head1 SEE ALSO

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-readonly-values-days at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Readonly-Values-Days>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Readonly::Values::Days

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Readonly-Values-Days>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Readonly-Values-Days>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Readonly-Values-Days>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Readonly::Values::Days>

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
